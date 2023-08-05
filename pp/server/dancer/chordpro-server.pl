#! perl

use v5.036;
use utf8;

# ChordPro as a web service.
#
# Interactive: http://127.0.0.1:5000/
#
# Or as a rendering service, e.g. using curl:
#
# curl -F 'song=@t.cho' http://127.0.0.1:5000/chordpro/pdf -o x.pdf

use App::Packager qw( :name ChordPro );
use ChordPro;
use Dancer2;
use Capture::Tiny qw( capture_stderr );
use File::Temp qw( tempdir tempfile );

# Common entry point, display form.

get '/' => sub {
    <<EOD;
<html>
<head>
<title>ChordPro Server</title>
<style>
form {
    font-family: Sans;
    font-size: 110%;
  }
</style>
</head>
<body>

<h1>ChordPro Server</h1>

<form action="http://127.0.0.1:5000/chordpro"
      method="POST"
      enctype="multipart/form-data">

<table>
  <tr>
    <td><label for="file">Select a ChordPro song:</label></td>
    <td><input type="file" name="song" required autofocus></td>
  </tr>
  <tr>
    <td><label for="config">Select a config (optional):</label></td>
    <td><input type="file" name="config"></td>
  </tr>
  <tr>
    <td><label for="css">Select a stylesheet (optional):</label></td>
    <td><input type="file" name="css"></td>
  </tr>
  <tr><td colspan=2">&nbsp;</td></tr>
  <tr>
    <td colspan="2">
      Convert to: 
      <input type="submit" name="type" value="HTML">
      &nbsp;
      <input type="submit" name="type" value="ChordPro">
      &nbsp;
      <input type="submit" name="type" value="PDF">
      &nbsp;or&nbsp;
      <input type="reset"> form</td>
    </tr>
  </table>
  </form>
<p>Powered by <a href="https://chordpro.org/" target="_blank">ChordPro</a> $ChordPro::VERSION</p>
</body>
</html>
EOD
};

# URLs for the converters:

post '/chordpro/html' => sub {
    return _convert("html");
};
post '/chordpro/chordpro' => sub {
    return _convert("chordpro");
};
post '/chordpro/pdf' => sub {
    return _convert("pdf");
};

post '/chordpro' => sub {
    my $type = lc param("type");
    return _convert($type);
};

sub _convert {
    my ( $type ) = @_;		# PDF, HTML, ChordPro

    state $dir = tempdir( CLEANUP => 1 );

    # First, stash the song in a temp file.
    my ($fh,$fn) = tempfile( "${dir}CPXXXX", SUFFIX => ".cho" );
    my $data = request->upload('song');
    return 'Missing ChordPro data' unless $data;

    # # Copy it under the basename in our temp directory.
    # my $path = path( $dir, $data->basename );
    # if ( -e $path ) {
    # 	warning( "'$path' already exists" );
    # 	unlink($path);
    # }
    # $data->copy_to($path);

    # Pass it from memory, no temp file needed.
    my $song = Encode::decode_utf8($data->content);

    # Setup the command.
    local @ARGV = ( "--no-default-configs" );
    push( @ARGV, "--define", "html.styles.display=/css/chordpro.css" )
      if $type eq "html";

    # Check for a CSS style sheet for the HTML output.
    my $css = request->upload('css');
    if ( $css ) {
	$css = Encode::decode_utf8($css->content);
    }

    # Check for a config.
    my $cfg = request->upload('config');
    if ( $cfg ) {
	my $path = path( $dir, $cfg->basename );
	if ( -e $path ) {
	    warning( "'$path' already exists" );
	    unlink($path);
	}
	$cfg->copy_to($path);
	push( @ARGV, "--config", $path );
    }

    # Process...
    # HTML and ChordPro are returned inline.
    for my $t ( qw( HTML ChordPro ) ) {
	next unless $type eq lc($t);

	# Output goes to scalar. No temp file needed.
	my $out = "";
	push( @ARGV, "--output", \$out );
	push( @ARGV, "--generate=$t" );
	push( @ARGV, \$song );
	my $stderr = capture_stderr { ::run() };

	if ( $out ) {
	    $out = Encode::decode_utf8($out);
	    if ( $type eq "html" && $css ) {
		$out =~ s;</head>;<style>\n$css</style>\n</head>;;
	    }
	    return template "show_".lc($type).".tt",
	      { output => $out,
		message => $stderr,
	      };
	}
    }

    # PDF is returned as a download.
    for my $t ( qw( PDF ) ) {
	next unless $type eq lc($t);

	my $of = $data->basename;
	$of .= "." . lc($t) unless $of =~ s/\.\K\w+$/lc($t)/e;
	my $out = path( $dir, $of );
	push( @ARGV, "--output", $out );
	push( @ARGV, "--generate=$t" );
	push( @ARGV, \$song );
	my $stderr = capture_stderr { ::run() };

	if ( -s $out ) {
	    send_file( $out, system_path => 1,
		       content_type => 'application/pdf',
		       filename => $of );
	}
    }

    return "Oops -- Something went wrong";
};

dance;

################ Subroutines ################

# Synchronous system call. Used in Util module.
sub ::sys { system(@_) }

__DATA__

@@ data.html
<h1>Config</h1>
<pre><%= $config %></pre>

<h1>Song</h1>
<pre><%= $song %></pre>

@@ chordpro.css
* {
    font-family: "sans";
}
div.song {
    page-break-after: always;
}
div.title {
    font-size: 18pt;
    font-weight: bold;
    /* position: running(title); */
}
div.subtitle {
    font-size: 16pt;
}
div.chorus {
    padding-left: 10pt;
    border-left: 2pt solid black;
}
div.verse {
}
div.tab {
    font-family: "mono";
    font-size: 10pt;
    white-space: pre;
    border: 1pt solid;
    padding: 2pt;
}
table tr td {
    /* border: 1pt solid red; */
    margin: 0pt;
    padding: 0pt;
}
table.songline {
    border-collapse: collapse;
}
table.songline + table.songline {
    margin-top: 0pt;
    margin-bottom: 0pt;
}
table.songline td {
    white-space: pre;
}
table.songline tr.chords {
    font-size: 12pt;
    font-style: italic;
    font-weight: bold;
    color: blue;
    page-break-after: avoid;
}
table.songline tr.lyrics {
    font-size: 12pt;
}
table.songline td.indent {
    padding-left: 2em;
}
div.comment span {
    background: #c0c0c0;
}
div.comment_italic span {
    background: #c0c0c0;
    font-style: italic;
}
div.image {
    object-fit: cover;
}
div + div, table + div, div + table {
    margin-top: 15pt;
}
@media print {
    @page {
	size: A4 portrait;
	@top-left {
	    /* Content specified by source style element. */
	    /* Until we have running headers and footers. */
	    /* content: element(title, first); */
	    font-size: 18pt;
	    font-weight: bold;
	}
	@top-center {
	    font-size: 18pt;
	    font-weight: bold;
	}
	@bottom-left {
	    font-size: 8pt;
	    content: "Produced by ChordProPlus";
	}
	@bottom-right {
	    font-size: 8pt;
	    content: "Page " counter(page) " of " counter(pages);
	}
    }
    /* Until we have running headers and footers. */
    div.title {
	display: none;
    }
}
@@ chordpro_print.css
/* CSS for printing. */
@page {
    size: A4 portrait;
    @top-left {
	/* Content specified by source style element. */
	/* Until we have running headers and footers. */
	/* content: element(title, first); */
	font-size: 18pt;
	font-weight: bold;
    }
    @top-center {
	font-size: 18pt;
	font-weight: bold;
    }
    @bottom-left {
	font-size: 8pt;
	content: "Produced by ChordProPlus";
    }
    @bottom-right {
	font-size: 8pt;
	content: "Page " counter(page) " of " counter(pages);
    }
}

/* Until we have running headers and footers. */
div.title {
    display: none;
}

@@ form.html
<html>
  <head>
    <title>Trying</title>
  </head>
  <body>
    <form method="POST" action="http://127.0.0.1:3000/foo">
      <textarea name="config"></textarea>
      <textarea name="song">{title: Swing Low Sweet Chariot}
{subtitle: Traditional}

{start_of_chorus}
Swing [D]low, sweet [G]chari[D]ot,
Comin’ for to carry me [A7]home.
Swing [D7]low, sweet [G]chari[D]ot,
Comin’ for to [A7]carry me [D]home.
{end_of_chorus}

# Verse
I [D]looked over Jordan, and [G]what did I [D]see,
Comin’ for to carry me [A7]home.
A [D]band of angels [G]comin’ after [D]me,
Comin’ for to [A7]carry me [D]home.

{c: Chorus}
</textarea>
      <input type="submit">
    </form>
  </body>
</html>
