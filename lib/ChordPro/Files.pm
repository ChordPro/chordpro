#! perl

use v5.26;
use feature qw( signatures );
no warnings qw( experimental::signatures );
use utf8;

package ChordPro::Files;

# Generalize some file system operations so they use LongPath on Windows.
# This is necessary for long filenames and unicode filenames.

use ChordPro::Utils qw( is_msw );
use Encode qw( decode_utf8 encode_utf8 );

use Exporter 'import';
our @EXPORT;
our @EXPORT_OK;

if ( is_msw ) {
    require Win32::LongPath;
}

sub fs_open( $name, $mode = '<:utf8' ) {
    my $fd;
    my $uname = $name;
    if ( utf8::is_utf8($uname) ) {
	if ( is_msw ) {
	    Win32::LongPath::openL( \$fd, $mode, $uname )
		or die("$name: $^E\n");
	    return $fd;
	}
	$uname = encode_utf8($name);
    }
    open( $fd, $mode, $uname )
      or die("$name: $!\n");
    return $fd;
}

push( @EXPORT, qw(fs_open) );

sub fs_test( $name, $test = 's' ) {
    if ( utf8::is_utf8($name) ) {
	return Win32::LongPath::testL( $test, $name ) if is_msw;
	$name = encode_utf8($name);
    }

    if    ( $test eq 'b' ) { return -b $name }
    elsif ( $test eq 'c' ) { return -c $name }
    elsif ( $test eq 'd' ) { return -d $name }
    elsif ( $test eq 'e' ) { return -e $name }
    elsif ( $test eq 'f' ) { return -f $name }
    elsif ( $test eq 'l' ) { return -l $name }
    elsif ( $test eq 'o' ) { return -o $name }
    elsif ( $test eq 'O' ) { return -O $name }
    elsif ( $test eq 'r' ) { return -r $name }
    elsif ( $test eq 'R' ) { return -R $name }
    elsif ( $test eq 's' ) { return -s $name }
    elsif ( $test eq 'w' ) { return -w $name }
    elsif ( $test eq 'W' ) { return -W $name }
    elsif ( $test eq 'x' ) { return -x $name }
    elsif ( $test eq 'X' ) { return -X $name }
    elsif ( $test eq 'z' ) { return -z $name }
    else { die("Invalid test '$test' for $name\n") }
}

push( @EXPORT, qw(fs_test) );

sub fs_unlink( $name ) {
    if ( utf8::is_utf8($name) ) {
	return Win32::LongPath::unlinkL($name) if is_msw;
	$name = encode_utf8($name);
    }
    unlink($name);
}

push( @EXPORT, qw(fs_unlink) );

sub fs_find( $folder, $opts = {} ) {

    my $filter = $opts->{filter} // qr/[.]/i;
    my $recurse = $opts->{recurse} // 1;
    $opts->{subfolders} = 0;

    unless ( is_msw ) {
	my $ufolder = $folder;
	if ( utf8::is_utf8($folder) ) {
	    $ufolder = encode_utf8($folder);
	}

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

    sub search_tree( $path, $opts ) {

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
		push( @files, @{ search_tree( $name, $opts ) } )
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
	     @{ search_tree( $folder, $opts ) } ];

}

push( @EXPORT, qw(fs_find) );

1;
