#! perl

use v5.26;
use feature qw( signatures );
no warnings qw( experimental::signatures );
use utf8;

package ChordPro::Files;

# Generalize some file system operations so they use LongPath on Windows.
# This is necessary for long filenames and unicode filenames.

# NOTE: FILENAMES SHOULD AT ALL TIMES BE PERL STRINGS!

# Where do filenames come from?
#
# 1. Command line arguments. Decode ASAP.
# 2. File (and directory) dialogs: Always perl string.
# 3. Preferences, configs, recents: should all be perl strings.
# 4. From filelists. We expect these lists to have UTF8 filenames that
#    get decoded when the list is read.

use Encode qw( decode_utf8 encode_utf8 );
use Ref::Util qw(is_ref);

use Exporter 'import';
our @EXPORT;
our @EXPORT_OK;

################ Platforms ################

use constant MSWIN => $^O =~ /MSWin|Windows_NT/i ? 1 : 0;

sub is_msw ()   { MSWIN }
sub is_macos () { $^O =~ /darwin/ }
sub is_wx ()    { main->can("OnInit") }

push( @EXPORT, qw( is_msw is_macos is_wx ) );

if ( is_msw ) {
    require Win32::LongPath;
}

################ ################

# General pattern:
# If Windows, call Windows specific function.
# Otherwise
#  If the filename contains UTF8 characters, encode.
#  Call standard perl function.

sub fs_open( $name, $mode = '<:utf8' ) {
    my $fd;
    if ( is_msw ) {
	Win32::LongPath::openL( \$fd, $mode, $name )
	    or die("$name: $^E\n");
	return $fd;
    }

    my $uname = $name;
    $uname = encode_utf8($name) if utf8::is_utf8($uname);

    open( $fd, $mode, $uname )
      or die("$name: $!\n");
    return $fd;
}

push( @EXPORT, qw(fs_open) );

sub fs_test( $tests, $name ) {
    my $res = 1;
    for my $test ( split( //, $tests ) ) {
	$res = _fs_test( $test, $name );
	return unless $res;
    }
    $res;
}

sub _fs_test( $test, $name ) {
    return Win32::LongPath::testL( $test, $name ) if is_msw;

    my $uname = $name;
    $uname = encode_utf8($name) if utf8::is_utf8($uname);

    if    ( $test eq 'b' ) { return -b $uname }
    elsif ( $test eq 'c' ) { return -c $uname }
    elsif ( $test eq 'd' ) { return -d $uname }
    elsif ( $test eq 'e' ) { return -e $uname }
    elsif ( $test eq 'f' ) { return -f $uname }
    elsif ( $test eq 'l' ) { return -l $uname }
    elsif ( $test eq 'o' ) { return -o $uname }
    elsif ( $test eq 'O' ) { return -O $uname }
    elsif ( $test eq 'r' ) { return -r $uname }
    elsif ( $test eq 'R' ) { return -R $uname }
    elsif ( $test eq 's' ) { return -s $uname }
    elsif ( $test eq 'w' ) { return -w $uname }
    elsif ( $test eq 'W' ) { return -W $uname }
    elsif ( $test eq 'x' ) { return -x $uname }
    elsif ( $test eq 'X' ) { return -X $uname }
    elsif ( $test eq 'z' ) { return -z $uname }
    else { die("Invalid test '$test' for $name\n") }
}

push( @EXPORT, qw(fs_test) );

sub fs_unlink( $name ) {

    return Win32::LongPath::unlinkL($name) if is_msw;

    my $uname = $name;
    $uname = encode_utf8($name) if utf8::is_utf8($uname);
    unlink($uname);
}

push( @EXPORT, qw(fs_unlink) );

sub fs_find( $folder, $opts = {} ) {

    my $filter = $opts->{filter} // qr/[.]/i;
    my $recurse = $opts->{recurse} // 1;
    $opts->{subfolders} = 0;

    unless ( is_msw ) {
	my $ufolder = $folder;
	$ufolder = encode_utf8($folder) if utf8::is_utf8($folder);

	use File::Find qw(find);
	my @files;

	find sub {
	    if ( -d && $File::Find::name ne $folder ) {
		$File::Find::prune = !$recurse;
		$opts->{subfolders} = 1;
	    }
	    elsif ( -s _ && $_ =~ $filter ) {
		my $i = 0;
		my @st = stat(_);
		push( @files,
		      { name => decode_utf8($File::Find::name =~ s;^\Q$ufolder\E/?;;r),
			map { $_ => $st[$i++] }
			qw{ dev ino mode nlink uid gid rdev size
			    atime mtime ctime blksize blocks }
		      } );
	    }
	}, $ufolder;

	@files = sort { $a->{name} cmp $b->{name} } @files;
	return \@files;
    }

    sub search_tree( $path, $opts, $folder ) {

	my $filter = $opts->{filter} // qr/[.]/i;
	my $recurse = $opts->{recurse} // 1;
	my $dir = Win32::LongPath->new;
	my @files;
	$dir->opendirL($path)
	  or die ("$path: $^E\n");

	foreach my $file ( $dir->readdirL ) {
	    # Skip parent dir.
	    next if $file eq '..';
	    # Get file stats.
	    my $name = $file eq '.' ? $path : "$path/$file";
	    my $stat = Win32::LongPath::lstatL($name)
	      or die( "stat($name,", Win32::LongPath::getcwdL(), "): $^E\n" );

	    # Recurse if dir.
	    if (    ( $file ne '.' )
		 && ( ($stat->{attribs}
		       & ( Win32::LongPath::FILE_ATTRIBUTE_DIRECTORY()
			   | Win32::LongPath::FILE_ATTRIBUTE_REPARSE_POINT() ) )
		      == Win32::LongPath::FILE_ATTRIBUTE_DIRECTORY() ) ) {
		push( @files, @{ search_tree( $name, $opts, $folder ) } )
		  if $recurse;
		$opts->{subfolders} = 1;
		next;
	    }
	    $name =~ s;^\Q$folder\E/?;;;
	    push( @files, { #%$stat,
			    name => $name,
			    full => Win32::LongPath::abspathL($name) } )
	      if $file =~ $filter;
	}

	$dir->closedirL;
	return \@files;
    }

    return [ sort { $a->{name} cmp $b->{name} }
	     @{ search_tree( $folder, $opts, $folder ) } ];

}

push( @EXPORT, qw(fs_find) );

sub fs_copy( $from, $to ) {
    return Win32::LongPath::copyL( $from, $to ) if is_msw;

    $to   = encode_utf8($to)   if utf8::is_utf8($to);
    $from = encode_utf8($from) if utf8::is_utf8($from);

    use File::Copy;
    copy( $from, $to );
}

push( @EXPORT, qw(fs_copy) );

# Wrapper for File::LoadLines.

sub fs_load( $name, $opts = {} ) {

    use File::LoadLines;

    $opts->{fail} //= "soft";

    my $ret;
    eval {
	if ( is_ref($name) ) {
	    $ret = loadlines( $name, $opts );
	}
	else {
	    my $fd = $name eq '-' ? \*STDIN : fs_open($name);
	    $ret = loadlines( $fd, $opts );
	    $opts->{_filesource} = $name;
	}
    };
    return $ret unless $@;

    my $msg = $@;
    $msg = $1 if $msg =~ /^\Q$name\E: (.*)$/;
    die( "$msg\n" ) unless $opts->{fail} eq "soft";
    $opts->{error} = $msg;
    return;
}

sub fs_blob( $name, $opts = {} ) {
    fs_load( $name, { blob => 1, %$opts } );
}

push( @EXPORT, qw(fs_load fs_blob) );

################ File::Spec functions ################

# Adapted from File::Spec::Functions 3.75.

# Function fn_catfile = File::Spec->catfile, etc.

use File::Spec;
require File::Spec::Unix;

my @funcs =
  qw( canonpath
      catdir
      catfile
      curdir
      rootdir
      updir
      is_absolute
      splitpath
      catpath
      path
      devnull
      tmpdir
      splitdir
      abs2rel
      rel2abs
      case_tolerant
   );
push( @EXPORT, map { "fn_$_" } @funcs );

my %udeps = ( canonpath	      => [],
	      catdir	      => [ qw(canonpath) ],
	      catfile	      => [ qw(canonpath catdir) ],
	      case_tolerant   => [],
	      curdir	      => [],
	      devnull	      => [],
	      rootdir	      => [],
	      updir	      => [],
);

foreach my $meth ( @funcs ) {
    $meth = 'file_name_is_absolute' if $meth eq 'is_absolute';
    my $sub = File::Spec->can($meth);
    no strict 'refs';
    if ( exists( $udeps{$meth} )
	 && $sub == File::Spec::Unix->can($meth)
	 && !( grep { File::Spec->can($_) != File::Spec::Unix->can($_) }
	            @{$udeps{$meth} } )
	 && defined( &{"File::Spec::Unix::_fn_$meth"} ) ) {
        *{"fn_$meth"} = \&{"File::Spec::Unix::_fn_$meth"};
    }
    else {
	$meth = 'is_absolute' if $meth eq 'file_name_is_absolute';
        *{"fn_$meth"} = sub { &$sub( 'File::Spec', @_) };
    }
}

1;
