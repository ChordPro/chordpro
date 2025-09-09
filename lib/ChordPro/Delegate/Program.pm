#! perl

use v5.26;
use strict;
use warnings;
use feature qw( signatures );
no warnings "experimental::signatures";
use utf8;

package ChordPro::Delegate::Program;

=for docs

** EXPERIMENTAL ** EXPERIMENTAL ** EXPERIMENTAL ** EXPERIMENTAL **

Experimental delegate to produce an image by running an external program.

Example config file:

  delegates {

    // Emulate the 'ly' environment using Program delegate.

    ly {
	// Fixed.
	module  : Program
	handler : cmd2image
	type    : image

	// The program / command to execute.
	program : /usr/bin/lilypond

	// Input.
	// Use value "stdin" to pass data via standard input.
	// Use value "argfileN" or "argfile" to pass data via temporary
	// file whose name is appended to the command arguments.
	// Use value "argfile0" to pass data via temporary file
	// whose name is prepended to the command arguments.
	// Alternatively, the name of one of the predefined temporary
	// files (%{tmpfile1} and %{tmpfile2}) can be used. Do not
	// forget to add this name to the command arguments.
	input   : argfile

	// Get the resultant output from a (temporary) file.
	// Use value "stdout" to collect results from standard output.
	// Note that lilypond will append "cropped.svg", so we pass
	// the base of the file names.
	result  : "%{tmpbase}.cropped.svg"

	// Command argumenta.
	args    : [ -dno-point-and-click --svg --silent
		    // Output to...
		    --output "%{tmpbase}"
		    // Input from... (appended, see "argfile" above)
		  ]

        // Preprocessing. "first" and "last" are applied to the whole
        // data at once. "lines" is applied line by line, after "first"
        // and before "last".
        preprocess {
            first : [ {...} ]
            lines : [ {...} ]
            last  : [ {...} ]
        }

	// (Optional) Input lines to prepend to the user data.
	preamble : [
	    '\\version "2.21.0"'
	    "#(ly:set-option 'crop #t)",
	    "\\header { tagline = ##f }"
	]

	// (Optional) Input lines to apppend to the user data.
	postamble : []

	// Default alignment is center, but ly delegate wants left.
	align     : left

    }
  }

Example of usage:

  {start_of_ly}
  \relative c''{ c d e f }
  {end_of_ly}

Notes:

  * No attribute options in the input.

=cut

use ChordPro::Files;
use ChordPro::Utils qw(dimension maybe make_preprocessor);
use ChordPro::Output::Common qw(fmt_subst);
use IPC::Run3 qw(run3);
use Ref::Util qw( is_arrayref );
use ChordPro::Utils qw(detect_image_format);

sub DEBUG() { $::config->{debug}->{x1} }

sub cmd2image( $song, %args ) {
    my $elt = $args{elt};
    my $ctl = { %{ $::config->{delegates}->{$elt->{context}} } };
    _cmd2image( $song, $ctl, %args );
}

sub _cmd2image( $song, $ctl, %args ) {
    my $elt = $args{elt};
    my $kv = { %{$elt->{opts}} };
    my $context = $elt->{context};

    # Default alignment.
    $kv->{align} //= $ctl->{align};

    if ( DEBUG > 1 ) {
	use DDP; p %args, as => "args";
	use DDP; p $elt,  as => "elt";
	use DDP; p $kv,   as => "opts";
	use DDP; p $ctl,  as => "ctl";
    }

    # Predefined temporary (file) names.
    state $imgcnt++;
    state $td = File::Temp::tempdir( CLEANUP => !DEBUG );
    my $tmpbase   = fn_catfile( $td, "tmp${imgcnt}" );
    my $tmpfile1  = fn_catfile( $td, "tmp${imgcnt}a.tmp" );
    my $tmpfile2  = fn_catfile( $td, "tmp${imgcnt}b.tmp" );

    # Prepare meta for substitutions.
    my $ss = { meta => { %{$song->{meta}},
			 tmpdir   => $td,
			 tmpbase  => $tmpbase,
			 tmpfile1 => $tmpfile1,
			 tmpfile2 => $tmpfile2,
			 %$kv } };
    my $subst = sub($t) { defined($t) ? fmt_subst( $ss, $t ) : "" };

    # Transfer command arguments.
    my @cmd;
    for ( @{$ctl->{args}} ) {
	push( @cmd, $subst->($_) );
    }

    #### Input handling ####

    my $input  = $subst->($ctl->{input})  || "stdin";
    my @data = @{$elt->{data}};

    # Preprocessor.
    my $prep = make_preprocessor( $ctl->{preprocess} );

    my $data;
    if ( $prep->{first} ) {
	$data = join( "\n", @data );
	$::config->{debug}->{pp} && warn("PRE[first]: ---\n", $data, "\n---\n");
	$prep->{first}->($data);
	$::config->{debug}->{pp} && warn("POST[first]: ---\n", $data, "\n---\n");
    }

    if ( $prep->{lines} ) {
	@data = split( /\n/, $data ) if defined $data;
	undef $data;
	while ( @data ) {
	    $_ = shift(@data);
	    $::config->{debug}->{pp} && warn("PRE:  ", $_, "\n");
	    $prep->{lines}->($_);
	    $::config->{debug}->{pp} && warn("POST: ", $_, "\n");
	    if ( /\n/ ) {
		my @a = split( /\n/, $_ );
		unshift( @data, @a );
	    }
	}
    }

    if ( $prep->{last} ) {
	$data = join( "\n", @data ) unless defined $data;
	$::config->{debug}->{pp} && warn("PRE[last]: ---\n", $data, "\n---\n");
	$prep->{last}->($data);
	$::config->{debug}->{pp} && warn("POST[last]: ---\n", $data, "\n---\n");
    }
    @data = split( /\n/, $data ) if defined $data;

    # Optional pre- and postamble.
    if ( is_arrayref($ctl->{preamble}) ) {
	unshift( @data, @{ $ctl->{preamble} } );
    }

    if ( is_arrayref($ctl->{postamble}) ) {
	push( @data, @{ $ctl->{postamble} } );
    }

    my $input_data;
    if ( $input eq 'stdin' ) {
	$input_data = join( "\n", @data );
	DEBUG && ::dump( $input_data, as => "Input from $input");
    }
    else {
	if ( $input =~ /^argfile[0N]?$/i ) {
	    my $pos = uc($1 // "N");
	    $input = fn_catfile( $td, "tmp${imgcnt}.in" );
	    if ( $pos eq "0" ) {
		unshift( @cmd, $input );
	    }
	    else {
		push( @cmd, $input );
	    }
	}

	# Store input data in temp file.
	my $fd = fs_open( $input, '>:utf8' );
	print $fd "$_\n" for @data;
	close($fd);
	DEBUG && ::dump( \@data, as => "Input from $input");
    }

    #### Output handling ####

    my $result = $subst->($ctl->{result}) || "stdout";
    DEBUG && warn("Result to $result\n");

    #### Diagnostics handling ####

    my $errors = $subst->($ctl->{errors}) || "stderr";

    #### Run time ####

    unshift( @cmd, $subst->($ctl->{program}) );
    DEBUG && ::dump( \@cmd,  as => "Command:" );

    my $stdout_buf = '';
    my $stderr_buf = '';

    my $status;
    if ( is_wx ) {
	DEBUG && warn("Using Wx::ExecuteStdoutStderr\n");
	( $status, $stdout_buf, $stderr_buf ) =
	  Wx::ExecuteStdoutStderr( "@cmd" );
	# $stdout_buf and $stderr_buf will be strings.
    }
    else {
	DEBUG && warn("Using IPC::Run3::run3\n");
	$stdout_buf = '';
	$stderr_buf = '';
	run3( \@cmd, \$input_data, \$stdout_buf, \$stderr_buf,
	      { binmode_stdout => ':raw',
		return_if_system_error => 1 } );
	# $stdout_buf and $stderr_buf will be strings.
	$status = $? >> 8;
    }

    if ( DEBUG ) {
	::dump( $stdout_buf, as => "Raw result (status: $status)" );
	::dump( $stderr_buf, as => "Raw diagnostics" );
	my $files = fs_find( $td, { filter => qr/^[^.]/ } );
	warn("Temp files:\n") if @$files;
	for ( @$files ) {
	    warn( "  ", fn_catfile( $td, $_->{name} ),
		  ", ", $_->{size}, " bytes\n" );
	}
    }

    my $o = { fail => 'soft' };
    if ( $result eq 'stdout'  ) {
	$result = $stdout_buf;
    }
    else {
	$result = fs_blob( $result, $o );
    }
    if ( $o->{error} ) {
	warn("?Error fetching results: ", $o->{error}, "\n" );
	return;
    }
    DEBUG && ::dump( $result, as => "Result" );

    $o = { fail => 'soft' };
    $errors = fs_load( \$stderr_buf, $o );
    if ( $o->{error} ) {
	warn("?Error fetching diagnostics: ", $o->{error}, "\n" );
	return;
    }

    if ( $errors && @$errors ) {
	warn("Diagnostics from delegate '", $elt->{context}, "':\n");
	warn("$_\n") for @$errors;
    }

    if ( $status ) {
	warn("?Error excuting @cmd (status = $status)\n");
	return;
    }

    if ( !$result ) {
	warn("?Error excuting @cmd (no output?)\n");
	return;
    }

    my $subtype;
    unless ( $subtype = $ctl->{subtype} ) {
	# Get info.
	my $info = detect_image_format(\$result);
	if ( $info->{error} ) {
	    warn("?Error executing @cmd: ", $info->{error}, "\n");
	    return;
	}
	$subtype = $info->{file_ext};
    }
    $result = [ $result ] if $subtype eq 'svg';

    # Finish.
    my $scale;
    my $design_scale;
    $kv->{scale} = dimension( $kv->{scale}//1, width => 1 );
    if ( $kv->{scale} != 1 ) {
	if ( $kv->{id} ) {
	    $design_scale = $kv->{scale};
	}
	else {
	    $scale = $kv->{scale};
	}
    }
    return
	  { type    => $ctl->{type},
	    line    => $elt->{line},
	    subtype => $subtype,
	    data    => $result,
	    opts => { maybe id           => $kv->{id},
		      maybe align        => $kv->{align},
		      maybe spread       => $kv->{spread},
		      maybe scale        => $scale,
		      maybe design_scale => $design_scale,
		    } };
}

# Pre-scan.
sub options( $data ) { {} }

1;
