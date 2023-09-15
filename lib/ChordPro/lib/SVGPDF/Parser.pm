#! perl

use v5.26;
use Object::Pad;
use utf8;

# SVG Parser, based on a modified version of XML::Tiny.

class SVGPDF::Parser;

use File::LoadLines;
use Carp;

field $debug;

method parse_file ( $fname, %args ) {
    $debug = $args{debug} if defined $args{debug};
    my $data = loadlines( $fname, { split => 0, chomp => 0 } );
    $self->parse( $data, %args );
}

method parse ( $data, %args ) {
    if ( $debug ) {
	# Make it easier to read/write long lines and disable parts.
	$data =~ s/^#.*//mg;
	$data =~ s/\\[\n\r]+\s*//g;
    }
    $self->_parse( $data, %args );
}

# The _parse method is a modified version of XML::Tiny. All comments
# and restrictions of L<XML::Tiny> are applicable.
# Main modification is to allow whitespace elements in <text> elements.
# These are significant in SVG.
# Since we're aiming at SVG parsing, and SVG is strict XML but often
# wrapped in an (X)HTML document, the parser functionality is set
# to no fatal_declarations and strict_entity_parsing.

field $re_name;
field %emap;

method _parse ( $data, %params) {
    my $elem = { content => [] };

    # TODO: Accept whitespace tokens by default within <text> elements.
    my $whitespace_tokens = $params{whitespace_tokens};

    $re_name //= '[:_a-z][\\w:\\.-]*';
    %emap = qw( lt < gt > amp & quot " apos ' );

    my $fixent = sub ( $e ) {
	$e =~ s/&#(\d+);/chr($1)/ge && return $e;
	$e =~ s/&#(x[0-9a-f]+);/chr(hex($1))/gie && return $e;
	$e =~ s/&(lt|gt|quot|apos|amp);/$emap{$1}/ge && return $e;
	croak( "SVG Parser: Illegal ampersand or entity \"$1\"" )
	   if $e =~ /(&[^;]{0,10})/;
	$e;
    };

    croak( "SVG Parser: No elements" ) if !defined($data) || $data !~ /\S/;

    # Illegal low-ASCII chars.
    croak( "SVG Parser: Not well-formed (illegal low-ASCII chars)" )
      if $data =~ /[\x00-\x08\x0b\x0c\x0e-\x1f]/;

    # Turn CDATA into PCDATA.
    $data =~ s{<!\[CDATA\[(.*?)]]>}{
        $_ = $1.chr(0);          # this makes sure that empty CDATAs become
        s/([&<>'"])/             # the empty string and aren't just thrown away.
            $1 eq '&' ? '&amp;'  :
            $1 eq '<' ? '&lt;'   :
            $1 eq '"' ? '&quot;' :
            $1 eq "'" ? '&apos;' :
                        '&gt;'
        /eg;
        $_;
    }egs;

    croak( "SVG Parser: Not well-formed (CDATA not delimited or bad comment)" )
      if $data =~ /]]>/		      # ]]> not delimiting CDATA
         || $data =~ /<!--(.*?)--->/s # ---> can't end a comment 
	 || grep { $_ && /--/ }
	         ( $data =~ /^\s+|<!--(.*?)-->|\s+$/gs); # -- in comm

    # Strip leading/trailing whitespace and comments (which don't nest - phew!).
    $data =~ s/^\s+|<!--(.*?)-->|\s+$//gs;
 
    # Turn quoted > in attribs into &gt;.
    # Double- and single-quoted attrib values get done seperately.
    while ( $data =~ s/($re_name\s*=\s*"[^"]*)>([^"]*")/$1&gt;$2/gsi ) {}
    while ( $data =~ s/($re_name\s*=\s*'[^']*)>([^']*')/$1&gt;$2/gsi ) {}

    if ( $params{fatal_declarations} && $data =~ /<!(ENTITY|DOCTYPE)/ ) {
        croak( "SVG Parser: Unexpected \"$1\"" );
    }

    # The abc2svg generator forgets the close the body. Fix it.
    if ( $data =~ /\<meta\s+name="generator"\s+content="abc2svg/ ) {
	$data =~ s;</div>\s*</html>;</div></body></html>;;
	$whitespace_tokens++;
    }

    # Ignore empty tokens/whitespace tokens.
    foreach my $token ( grep { length }
		        split( /(<[^>]+>)/, $data ) ) {
	next if $token =~ /^\s+$/s && !$whitespace_tokens;
        next if $token =~ /<\?$re_name.*?\?>/is
	        || $token =~ /^<!(ENTITY|DOCTYPE)/i;

	if ( $token =~ m!^</($re_name)\s*>!i ) {     # close tag
	    croak( "SVG Parser: Not well-formed (at \"$token\")" )
	      if $elem->{name} ne $1;
            $elem = delete $elem->{parent};
        }
	elsif ( $token =~ /^<$re_name(\s[^>]*)*(\s*\/)?>/is ) {   # open tag
            my ( $tagname, $attribs_raw ) =
	      ( $token =~ m!<(\S*)(.*?)(\s*/)?>!s );
            # First make attribs into a list so we can spot duplicate keys.
            my $attrib = [
		# Do double- and single- quoted attribs seperately.
                $attribs_raw =~ /\s($re_name)\s*=\s*"([^"]*?)"/gi,
                $attribs_raw =~ /\s($re_name)\s*=\s*'([^']*?)'/gi
            ];
            if ( @{$attrib} == 2 * keys %{{@{$attrib}}} ) {
                $attrib = { @{$attrib} }
            }
	    else {
		croak( "SVG Parser: Not well-formed (duplicate attribute)" );
	    }

            # Now trash any attribs that we *did* manage to parse and see
            # if there's anything left.
            $attribs_raw =~ s/\s($re_name)\s*=\s*"([^"]*?)"//gi;
            $attribs_raw =~ s/\s($re_name)\s*=\s*'([^']*?)'//gi;
            croak( "SVG Parser: Not well-formed ($attribs_raw)" )
	      if $attribs_raw =~ /\S/ || grep { /</ } values %{$attrib};

            unless ( $params{no_entity_parsing} ) {
                foreach my $key ( keys %{$attrib} ) {
                    ($attrib->{$key} = $fixent->($attrib->{$key})) =~
		      s/\x00//g; # get rid of CDATA marker
                }
            }
	    # We have an element. Push it.
            $elem = { content => [],
		      name    => $tagname,
		      type    => 'e',
		      attrib  => $attrib,
		      parent  => $elem
		    };
            push( @{ $elem->{parent}->{content} }, $elem );

            # Handle self-closing tags.
            if ( $token =~ /\s*\/>$/ ) {
                $elem->{name} =~ s/\/$//;
                $elem = delete( $elem->{parent} );
            }
        }
	elsif ( $token =~ /^</ ) { # some token taggish thing
            croak( "SVG Parser: Unexpected \"$token\"" );
        }
	else {                          # ordinary content
            $token =~ s/\x00//g; # get rid of our CDATA marker
            unless ( $params{no_entity_parsing} ) {
		$token = $fixent->($token);
	    }
            push( @{$elem->{content}},
		  { content => $token, type => 't' } );
        }
    }
    croak( "SVG Parser: Not well-formed (", $elem->{name}, " duplicated parent)" )
      if exists($elem->{parent});

    if ( $whitespace_tokens ) {
	while ( @{$elem->{content}} > 1
	     && $elem->{content}->[0]->{type} eq 't'
	     && $elem->{content}->[0]->{content} !~ /\S/
	   )
	  {
	      shift( @{$elem->{content}} );
	}
	while ( @{$elem->{content}} > 1
	     && $elem->{content}->[-1]->{type} eq 't'
	     && $elem->{content}->[-1]->{content} !~ /\S/
	   )
	  {
	      pop( @{$elem->{content}} );
	}
    }
    croak( "SVG Parser: Junk after end of document" )
      if @{$elem->{content}} > 1;
    croak( "SVG Parser: No elements?" )
      if @{$elem->{content}} == 0 || $elem->{content}->[0]->{type} ne 'e';

    return $elem->{content};
}

1;
