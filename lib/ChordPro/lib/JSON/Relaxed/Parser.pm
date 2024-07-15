#! perl

use v5.26;
use Object::Pad;
use utf8;

package JSON::Relaxed::Parser;

our $VERSION = "0.096";

class JSON::Relaxed::Parser;

# Instance data.
field $data    :mutator;	# RJSON string being parser
field @pretoks;			# string in pre-tokens
field @tokens;			# string as tokens

# Instance properties.

# Enforce strictness to official standard.
# Strict true -> RJSON conformant.
# Strict false (default) -> RRJSON. Everything goes :).
field $strict		   :mutator :param = 0;

# Allow extra stuff after the JSON structure.
# Strict mode only.
field $extra_tokens_ok	   :mutator :param = 0;

# Define the values to be used for true and false.
field $booleans		   :mutator :param = 1;

# Signal error with exceptions.
field $croak_on_error	   :mutator :param = 1;
field $croak_on_error_internal;

# Some non-strict extensions can be controlled individually.
# This may disappear in some futer version, so do not use.
# Extension: a.b:c -> a:{b:c}
## Non-strict only.
field $combined_keys	   :mutator :param = 1;

# Extension: a:b -> {a:b} (if outer)
## Non-strict only.
field $implied_outer_hash  :mutator :param = 1;

# Extension: = as :, and optional before {, off/on as false/true
## Non-strict only.
field $prp		    :mutator :param = 1;

# Formatted output.
field $pretty		    :mutator :param = 0;

# Retain key order. Warning: adds a key " key order " to each hash!
## Non-strict only.
field $key_order	    :mutator :param = 0;

# Error indicators.
field $err_id		    :accessor;
field $err_msg		    :accessor;
field $err_pos		    :accessor;

method decode( $str ) {
    $croak_on_error_internal = $croak_on_error;
    $self->_decode($str);
}

# Legacy.
method parse( $str ) {
    $croak_on_error_internal = 0;
    $self->_decode($str);
}

method _decode( $str ) {

    $data = $str;
    return $self->error('missing-input')
      unless defined $data && length $data;

    undef $err_id;
    $err_pos = -1;
    undef $err_msg;

    $self->pretokenize;
    return if $self->is_error;

    $self->tokenize;
    return $self->error('empty-input') unless @tokens;

    $self->structure( top => 1 );
}

################ Character classifiers ################

# Reserved characters.
#    '['  beginning of array
#    ']'  end of array
#    '{'  beginning of hash
#    '}'  end of hash
#    ':'  delimiter between name and value of hash element
#    ','  separator between elements in hashes and arrays

my $p_reserved = q<[,:{}\[\]]>;

method is_reserved ($c) {
    $c =~ /^$p_reserved$/;
}

# Newlines. CRLF (Windows), CR (MacOS) and newline (sane systems).

my $p_newlines = q{(?:\r\n|\r|\n|\\\n)};

method is_newline ($c) {
    $c =~ /^$p_newlines$/o;
}

# Quotes. Single, double and backtick.

my $p_quotes = q{["'`]};

method is_quote ($c) {
    $c =~ /^$p_quotes$/o;
}

# Numbers. A special case of unquoted strings.
my $p_number = q{[+-]?\d*\.?\d+(?:[Ee][+-]?\d+)?};

method pretokenize {

    # \u escape (4 hexits)
    my @p = ( qq<\\\\u[[:xdigit:]]{4}> );

    # Any escaped char (strict mode).
    if ( $strict ) {
	push( @p, qq<\\\\.> );
    }

    # Otherwise, match \u{ ... } also.
    else {
	push( @p, qq<\\\\u\\{[[:xdigit:]]+\\}>, qq<\\\\[^u]> ); # escaped char
    }

    if ( $prp && !$strict ) {
	# Add = to the reserved characters
        $p_reserved = q<[,=:{}\[\]]>;
	# Massage # comments into // comments without affecting position.
        $data =~ s/^(\s*)#.(.*)$/$1\/\/$2/gm;
        $data =~ s/^(\s*)#$/$1 /gm;
    }

    push( @p, $p_newlines,
	  qq< // [^\\n]* \\n >,	  # line comment
	  qq< /\\* .*? \\*/ >,	  # comment start
	  qq< /\\* >,		  # comment start
          qq< $p_reserved >,	  # reserved chars
	  qq< "(?:\\\\.|.)*?" >,  # "string"
	  qq< `(?:\\\\.|.)*?` >,  # `string`
	  qq< '(?:\\\\.|.)*?' >,  # 'string'
	  qq< $p_quotes >,	  # stringquote
	  qq< \\s+ > );		  # whitespace

    my $p = join( "|", @p );

    @pretoks = split( m< ( $p ) >sox, $data );

    # Remove empty strings.
    @pretoks = grep { length($_) } @pretoks;

    return;
}

# Accessor for @pretoks.
method pretoks() { \@pretoks }

method tokenize {

    @tokens = ();
    my $offset = 0;		# token offset in input

    if ( $booleans ) {
	if ( ref($booleans) ne 'ARRAY' ) {
	    $booleans = [ $JSON::Boolean::false, $JSON::Boolean::true ];
	}
    }
    else {
	$booleans = [ 0, 1 ];
    }

    my $glue = 0;		# can glue strings
    my $uq_open = 0;		# collecting pretokens for unquoted string

    # Loop through characters.
    while ( @pretoks ) {
	my $pretok = shift(@pretoks);

	# White space: ignore.
	if ( $pretok !~ /\S/ ) {
	    $offset += length($pretok);
	    $uq_open = 0;
	    next;
	}

	if ( $pretok eq "\\\n" ) {
	    $glue++ if $glue;
	    $uq_open = 0;
	    $offset += length($pretok);
	    next;
	}

	# Strings.
	if ( $pretok =~ /^(["'`])(.*?)\1$/s ) {
	    my ( $quote, $content ) = ( $1, $2 );
	    if ( $glue > 1 ) {
		$tokens[-1]->append($content);
	    }
	    else {
		$self->addtok( $content, 'Q', $offset, $quote );
		$glue = 1 unless $strict;
	    }
	    $offset += length($pretok);
	    $uq_open = 0;
	    next;
	}
	$glue = 0;

	# // comment.
	if ( $pretok =~ m<^//(.*)> ) {
	    # $self->addtok( $1, 'L', $offset );
	    $offset += length($pretok);
	    $uq_open = 0;
	}

	# /* comment */
	elsif ( $pretok =~ m<^/\*.+>s ) {
	    $offset += length($pretok);
	    $uq_open = 0;
	}

	elsif ( $pretok eq '/*' ) {
	    return $self->error('unclosed-inline-comment');
	}

	# Reserved characters.
	elsif ( $self->is_reserved($pretok) ) {
	    $self->addtok( $pretok, 'C', $offset );
	    $offset += length($pretok);
	    $uq_open = 0;
	}


	# Numbers.
	elsif ( $pretok =~ /^$p_number$/ ) {
	    $self->addtok( 0+$pretok, 'N', $offset );
	    $offset += length($pretok);
	    $uq_open = 0;
	}

	# Quotes
	# Can't happen -- should be an encosed string.
	elsif ( $self->is_quote($pretok) ) {
	    $offset += length($pretok);
	    $self->addtok( $pretok, '?', $offset );
	    return $self->error('unclosed-quote', $tokens[-1] );
	}

	# Else it's an unquoted string.
	else {
	    if ( $uq_open ) {
		$tokens[-1]->append($pretok);
	    }
	    else {
		$self->addtok( $pretok, 'U', $offset );
		$uq_open++;
	    }
	    $offset += length($pretok);
	}
    }
    return;
}

# Accessor for @tokens,
method tokens() { \@tokens }

# Add a new token to @tokens.
method addtok( $tok, $typ, $off, $quote=undef ) {

    push( @tokens,
	  $typ eq 'U' || $typ eq 'N'
	  ? JSON::Relaxed::String::Unquoted->new( token   => $tok,
						  content => $tok,
						  type    => $typ,
						  parent  => $self,
						  offset  => $off )
	  : $typ eq 'Q'
	    ? JSON::Relaxed::String::Quoted->new( token   => $tok,
						  type    => $typ,
						  content => $tok,
						  quote   => $quote,
						  parent  => $self,
						  offset  => $off )
	    : JSON::Relaxed::Token->new( token  => $tok,
					 parent => $self,
					 type   => $typ,
					 offset => $off ) );
}

# Build the result structure out of the tokens.
method structure( %opts ) {

    @tokens = @{$opts{tokens}} if $opts{tokens}; # for debugging

    if ( $implied_outer_hash && !$strict ) {
	# Note that = can only occur with $prp.
	if ( @tokens > 2 && $tokens[0]->is_string
	     && $tokens[1]->token =~ /[:={]/ ) {
	    $self->addtok( '}', 'C', $tokens[-1]->offset );
	    $self->addtok( '{', 'C', $tokens[0]->offset );
	    unshift( @tokens, pop(@tokens ));
	}
    }

    my $this = shift(@tokens) // return;
    my $rv;

    if ( $this->is_string ) { # (un)quoted string
	$rv = $this->as_perl;
    }
    else {
	my $t = $this->token;
	if ( $t eq '{' ) {
	    $rv = $self->build_hash;
	}
	elsif ( $t eq '[' ) {
	    $rv = $self->build_array;
	}
	else {
	    return $self->error( 'invalid-structure-opening-character',
				 $this );
	}
    }

    # If this is the outer structure, then no tokens should remain.
    if ( $opts{top}
	 && @tokens
	 && ( $strict || !$extra_tokens_ok )
	 && !$self->is_error
       ) {
	return $self->error( 'multiple-structures', $tokens[0] );
    }

    return $rv;
}


method error( $id, $aux = undef ) {
    require JSON::Relaxed::ErrorCodes;
    $err_id = $id;
    $err_pos = $aux ? $aux->offset : -1;
    $err_msg = JSON::Relaxed::ErrorCodes->message( $id, $aux );

    die( $err_msg, "\n" ) if $croak_on_error_internal;
    return;			# undef
}

method is_error() {
    $err_id;
}

# For debugging.
method dump_tokens() {
    my $tokens = \@tokens;
    return unless require DDP;
    if ( -t STDERR ) {
	DDP::p($tokens);
    }
    else {
	warn DDP::np($tokens), "\n";
    }
}

method build_hash() {

    my $rv = {};
    my @ko;			# order of keys

    while ( @tokens ) {
	my $this = shift(@tokens);
	# What is allowed after opening brace:
	#	closing brace
	#	comma
	#	string

	# If closing brace, return.
	my $t = $this->token;
	if ( $t eq '}' ) {
	    $rv->{" key order "} = \@ko
	      if $key_order && !$strict && @ko > 1;
	    return $rv;
	}

	# If comma, do nothing.
	next if $t eq ',';

	# String
	# If the token is a string then it is a key. The token after that
	# should be a value.
	if ( $this->is_string ) {
	    my ( $key, $value );

	    # Set key using string.
	    $key = $this->as_perl( always_string => 1 );
	    $self->set_value( $rv, $key );
	    if ( $key_order ) {
		if ( $combined_keys && !$strict ) {
		    push( @ko, $key =~ s/\..*//r );
		}
		else {
		    push( @ko, $key );
		}
	    }

	    my $next = $tokens[0];
	    # If anything follows the string.
	    last unless defined $next;

	    # A comma or closing brace is acceptable after a string.
	    next if $next->token eq ',' || $next->token eq '}';

	    # If next token is a colon or equals then it should be followed by a value.
	    # Note that = can only occur with $prp.
	    if ( $next->token =~ /^[:=]$/ ) {
		# Step past the colon.
		shift(@tokens);

		# If at end of token array, exit loop.
		last unless @tokens;

		# Get hash value.
		$value = $self->get_value;

		# If there is a global error, return undef.
		return undef if $self->is_error;
	    }

	    # Extension (prp): Implied colon.
	    elsif ( $prp && $next->token eq '{' ) {
		# Get hash value.
		$value = $self->get_value;

		# If there is a global error, return undef.
		return undef if $self->is_error;
	    }

	    # Anything else is an error.
	    else {
		return $self->error('unknown-token-after-key', $next );
	    }

	    # Set key and value in return hash.
	    $self->set_value( $rv, $key, $value );
	}

	# Anything else is an error.
	else {
	    return $self->error('unknown-token-for-hash-key', $this );
	}
    }

    # If we get this far then unclosed brace.
    return $self->error('unclosed-hash-brace');

}

method get_value() {

    # Get token.
    my $this = shift(@tokens);

    # Token must be string, array, or hash.

    # String.
    if ( $this->is_string ) {
	return $this->as_perl;
    }

    # Token opens a hash or array.
    elsif ( $this->is_list_opener ) {
	unshift( @tokens, $this );
	return $self->structure;
    }

    # At this point it's an illegal token.
    return $self->error('unexpected-token-after-colon', $this );
}

method set_value ( $rv, $key, $value = undef ) {
    return $rv->{$key} = $value
      unless $combined_keys && !$strict && $key =~ /\./s;

    my @keys = split(/\./, $key, -1 );
    my $c = \$rv;
    for ( @keys ) {
	if ( /^[+-]?\d+$/ ) {
	    $c = \( $$c->[$_] );
	}
	else {
	    $c = \( $$c->{$_} );
	}
    }
    $$c = $value;
}

method build_array() {

    my $rv = [];

    # Build array. Work through tokens until closing brace.
    while ( @tokens ) {
	my $this = shift(@tokens);

	my $t = $this->token;
	# Closing brace: we're done building this array.
	return $rv if $t eq ']';

	# Comma: if we get to a comma at this point, and we have
	# content, do nothing with it in strict mode. Ignore otherwise.
	if ( $t eq ',' && (!$strict || @$rv) ) {
	}

	# Opening brace of hash or array.
	elsif ( $this->is_list_opener ) {
	    unshift( @tokens, $this );
	    my $object = $self->structure;
	    defined($object) or return undef;
	    push( @$rv, $object );
	}

	# if string, add it to the array
	elsif ( $this->is_string ) {
	    # add the string to the array
	    push( @$rv, $this->as_perl );

	    # Check following token.
	    if ( @tokens ) {
		my $next = $tokens[0] || '';
		# Spec say: Commas are optional between objects pairs
		# and array items.
		# The next element must be a comma or the closing brace,
		# or a string or list.
		# Anything else is an error.
		unless ( $next->token =~ /^[,\]]$/
			 || $next->is_string
			 || $next->is_list_opener ) {
		    return $self->error( 'missing_comma-between-array-elements',
					 $next );
		}
	    }
	}

	# Else unkown object or character, so throw error.
	else {
	    return $self->error( 'unknown-array-token', $this );
	}
    }

    # If we get this far then unclosed brace.
    return $self->error('unclosed-array-brace');
}

method is_comment_opener( $pretok ) {
    $pretok eq '//' || $pretok eq '/*';
}

sub min { $_[0] < $_[1] ? $_[0] : $_[1] }
sub max { $_[0] > $_[1] ? $_[0] : $_[1] }

method encode(%opts) {
    my $schema  = $opts{schema};
    my $level   = $opts{level}              // 0;
    my $rv      = $opts{data};			# allow undef
    my $indent  = $opts{indent}             // 2;
    my $impoh   = $opts{implied_outer_hash} // $implied_outer_hash;
    my $ckeys   = $opts{combined_keys}      // $combined_keys;
    my $prpmode = $opts{prp}                // $prp;
    my $pretty  = $opts{pretty}             // $pretty;
    my $strict  = $opts{strict}             // $strict;
    my $nouesc  = $opts{nounicodeescapes}   // 0;

    if ( $strict ) {
	$ckeys = $prpmode = $impoh = 0;
    }

    $schema = resolve( $schema, $schema ) if $schema;

    my $s = "";
    my $i = 0;
    my $props = $schema->{properties};
    #warn("L$level - ", join(" ", sort keys(%$props)),"\n");

    # Add comments from schema, if any.
    my $comments = sub( $p ) {
	my $s = "";
	my $did = 0;#$level;
	for my $topic ( qw( title description ) ) {
	    next unless $p->{$topic};
	    $s .= "\n" unless $did++;
	    $s .= (" " x $i) . "// $_\n"
	      for split( /\s*<br\/?>|\\n|\n/, $p->{$topic} );
	}
	return $s;
    };

    if ( !$level ) {
	$s .= $comments->($schema);
    }

    # Format a string value.
    my $pr_string = sub ( $str, $force = 0 ) {

	# Reserved strings.
	if ( !defined($str) ) {
	    return "null";
	}

	if ( UNIVERSAL::isa( $str, 'JSON::Boolean' ) ) {
	    return "".$str;	# force string result
	}

	my $v = $str;

	# Escapes.
	$v =~ s/\\/\\\\/g;
	$v =~ s/\n/\\n/g;
	$v =~ s/\r/\\r/g;
	$v =~ s/\f/\\f/g;
	$v =~ s/\013/\\v/g;
	$v =~ s/\010/\\b/g;
	$v =~ s/\t/\\t/g;
	$v =~ s/([^ -ÿ])/sprintf( ord($1) < 0xffff ? "\\u%04x" : "\\u{%x}", ord($1))/ge unless $nouesc;

	# Force quotes unless the string can be represented as unquoted.
	if ( # contains escapes
	     $v ne $str
	     # not value-formed numeric
	     || ( $v =~ /^$p_number$/ && 0+$v ne $v )
	     # contains reserved, quotes or spaces
	     || $v =~ $p_reserved
	     || $v =~ $p_quotes
	     || $v =~ /\s/
	     || $v =~ /^(true|false|null)$/
	     || !length($v)
	   ) {
	    if ( $v !~ /\"/ ) {
		return '"' . $v . '"';
	    }
	    if ( $v !~ /\'/ ) {
		return "'" . $v . "'";
	    }
	    if ( $v !~ /\`/ ) {
		return "`" . $v . "`";
	    }
	    return '"' . ($v =~ s/(["'`])/\\$1/rg) . '"';
	}

	# Just a string.
	return $v;
    };

    # Format an array value.
    my $pr_array = sub ( $rv, $level=0, $props = {} ) {
	return "[]" unless @$rv;

	# Gather list of formatted values.
	my @v = map { $self->encode( %opts,
				     data   => $_,
				     level  => $level+1,
				     schema => $props,
				   ) } @$rv;

	return "[".join(",",@v)."]" unless $pretty;

	# If sufficiently short, put it on one line.
	if ( $i + length("@v") < 72
	     && join("",@v) !~ /\s|$p_newlines/ ) {
	    return "[ @v ]";
	}

	# Put the values on separate lines.
	my $s = "[\n";
	$s .= s/^/(" " x ($i+$indent))/gemr . "\n" for @v;
	$s .= (" " x $i) . "]";

	return $s;
    };

    # Format a hash value.
    my $pr_hash; $pr_hash = sub ( $rv, $level=0, $props = {} ) {
	return "{}" unless keys(%$rv);

	my $s = "";

	# Opening brace.
	if ( $level || !$impoh ) {
	    $s .= $pretty ? "{\n" : "{";
	    $i += $indent;
	}

	# If we have a key order, use this and delete.
	my @ko = $rv->{" key order "}
	  ? @{ delete($rv->{" key order "}) }
	  : sort(keys(%$rv));

	my $ll = 0;
	for ( @ko ) {
	    # This may be wrong if \ escapes or combined keys are involved.
	    $ll = length($_) if length($_) > $ll;
	}

	for ( @ko ) {
	    my $k = $_;

	    # Gather comments, if available.
	    my $comment;
	    if ( $props->{$k} ) {
		$comment = $comments->($props->{$k});
		$s .= $comment if $comment;
	    }

	    my $v = $rv->{$k};
	    my $key = $k;	# final key
	    # Combine keys if allowed and possible.
	    while ( $ckeys && ref($v) eq 'HASH' && keys(%$v) == 1 ) {
		my $k = (keys(%$v))[0];
		$key .= ".$k";	# append to final key
		$v = $v->{$k};	# step to next
	    }

	    $s .= (" " x $i) if $pretty;

	    # Format the key, try to align on length. NEEDS WORK
	    my $t = $pr_string->($key);
	    my $l = length($t);
	    $s .= $t;
	    my $in = $comment ? "" : " " x max( 0, $ll-length($t) );

	    # Handle object serialisation.
	    my $r = UNIVERSAL::can( $v, "TO_JSON" ) // UNIVERSAL::can( $v, "FREEZE" );
	    $r = $r ? $v->$r : $v;

	    # Format the value.
	    if ( ref($r) eq 'HASH' ) {
		# Make up and recurse.
		if ( $pretty ) {
		    $s .= $prpmode ? " " : " : ";
		}
		elsif ( !$prpmode ) {
		    $s .=  ":";
		}

		$s .= $pr_hash->( $r, $level+1, $props->{$k}->{properties} );
	    }

	    elsif ( ref($r) eq 'ARRAY' ) {
		$s .= $pretty ? "$in : " : ":";
		$s .= $pr_array->( $r, $level+1, $props->{$k}->{items} );
	    }

	    elsif ( $pretty ) {
		my $t = $pr_string->($r);
		$s .= "$in : ";

		# Break quoted strings that contain pseudo-newlines.
		if ( $t =~ /^["'`].*\\n/ ) {
		    # Remove the quotes/
		    my $quote = substr( $t, 0, 1, '');
		    chop($t);

		    # Determine current indent.
		    $s =~ /^(.*)\Z/m;
		    my $sep = " \\\n" . (" " x length($1));

		    # Get string parts.
		    my @a = split( /\\n/, $t, -1 );
		    while ( @a ) {
			$s .= $quote.shift(@a);
			$s .= "\\n" if @a;
			$s .= $quote;
			$s .= $sep if @a;
		    }
		}

		# Just a string.
		else {
		    $s .= $t;
		}
	    }
	    else {
		$s .= ":" . $pr_string->($r) . ",";
	    }
	    $s .= "\n" if $pretty;
	}

	# Strip final comma.
	$s =~ s/,$// unless $pretty;

	# Closing brace,.
	if ( $level || !$impoh ) {
	    $i -= $indent;
	    $s .= (" " x $i) if $pretty;
	    $s .= "}";
	}
	else {
	    $s =~ s/\n+$//;
	}

	return $s;
    };

    # Handle object serialisation.
    my $r = UNIVERSAL::can( $rv, "TO_JSON" ) // UNIVERSAL::can( $rv, "FREEZE" );
    $r = $r ? $rv->$r : $rv;

    # From here it is straight forward.
    if ( ref($r) eq 'HASH' ) {
	$s .= $pr_hash->( $r, $level, $props );
    }
    elsif ( ref($r) eq 'ARRAY' ) {
	$s .= $pr_array->( $r, $level );
    }
    else {
	$s .= $pr_string->($r);
    }

    # Final make-up.
    if ( $pretty && !$level ) {
	$s =~ s/^\n*//s;
	$s .= "\n" if $s !~ /\n$/;
    }
    return $s;
}

################ Subroutines ################

# resolve processes $ref, allOf etc nodes.

sub resolve( $d, $schema ) {

    if ( is_hash($d) ) {
	while ( my ($k,$v) = each %$d ) {
	    if ( $k eq 'allOf' ) {
		delete $d->{$k}; # yes, safe to do
		$d = merge( resolve( $_, $schema ), $d ) for @$v;
	    }
	    elsif ( $k eq 'oneOf' || $k eq 'anyOf' ) {
		delete $d->{$k}; # yes, safe to do
		$d = merge( resolve( $v->[0], $schema ), $d );
	    }
	    elsif ( $k eq '$ref' ) {
		delete $d->{$k}; # yes, safe to do
		if ( $v =~ m;^#/definitions/(.*); ) {
		    $d = merge( resolve( $schema->{definitions}->{$1}, $schema ), $d );
		}
		else {
		    die("Invalid \$ref: $v\n");
		}
	    }
	    else {
		$d->{$k} = resolve( $v, $schema );
	    }
	}
    }
    elsif ( is_array($d) ) {
	$d = [ map { resolve( $_, $schema ) } @$d ];
    }
    else {
    }

    return $d;
}

sub is_hash($o)  { UNIVERSAL::isa( $o, 'HASH'  ) }
sub is_array($o) { UNIVERSAL::isa( $o, 'ARRAY' ) }

sub merge ( $left, $right ) {

    return $left unless $right;

    my %merged = %$left;

    for my $key ( keys %$right ) {

        my ($hr, $hl) = map { is_hash($_->{$key}) } $right, $left;

        if ( $hr and $hl ) {
            $merged{$key} = merge( $left->{$key}, $right->{$key} );
        }
        else {
            $merged{$key} = $right->{$key};
        }
    }

    return \%merged;
}

################ Tokens ################

class JSON::Relaxed::Token;

field $parent :accessor :param;
field $token  :accessor :param;
field $type   :accessor :param;
field $offset :accessor :param;

method is_string() {
    $type =~ /[QUN]/
}

method is_list_opener() {
    $type eq 'C' && $token =~ /[{\[]/;
}

method as_perl( %options ) {	# for values
    $token->as_perl(%options);
}

method _data_printer( $ddp ) {	# for DDP
    my $res = "Token(";
    if ( !defined $token ) {
	$res .= "null";
    }
    elsif ( $self->is_string ) {
	$res .= $token->_data_printer($ddp);
    }
    else {
	$res .= "\"$token\"";
    }
    $res .= ", $type";
    $res . ", $offset)";
}

method as_string {		# for messages
    my $res = "";
    if ( $self->is_string ) {
	$res = '"' . ($self->content =~ s/"/\\"/gr) . '"';
    }
    else {
	$res .= "\"$token\"";
    }
    $res;
}

=begin heavily_optimized_alternative

package JSON::Relaxed::XXToken;
our @ISA = qw(JSON::Relaxed::Parser);

sub new {
    my ( $pkg, %opts ) = @_;
    my $self = bless [] => $pkg;
    push( @$self,
	  delete(%opts{parent}),
	  delete(%opts{token}),
	  delete(%opts{type}),
	  delete(%opts{offset}),
    );
    $self;
}

sub parent { $_[0]->[0] }
sub token  { $_[0]->[1]  }
sub type   { $_[0]->[2]   }
sub offset { $_[0]->[3] }

sub is_string { $_[0]->[2] =~ /[QUN]/  }
sub is_list_opener { $_[0]->[2] eq 'C' && $_[0]->[1] =~ /[{\[]/ }
sub as_perl {	# for values
    return shift->[1]->as_perl(@_);
}

sub _data_printer {	# for DDP
    my ( $self, $ddp ) = @_;
    my $res = "Token(";
    if ( $self->is_string ) {
	$res .= $self->[1]->_data_printer($ddp);
    }
    else {
	$res .= "\"".$self->[1]."\"";
    }
    $res .= ", " . $self->[2];
    $res . ", " . $self->[3] . ")";
}

sub as_string {		# for messages
    if ( $_[0]->is_string ) {
	return '"' . ($_[0]->[1]->content =~ s/"/\\"/gr) . '"';
    }
    "\"" . $_[0]->[1] . "\"";
}

=cut

################ Strings ################

class JSON::Relaxed::String :isa(JSON::Relaxed::Token);

field $content	:param = undef;
field $quote	:accessor :param = undef;

# Quoted strings are assembled from complete substrings, so escape
# processing is done on the substrings. This prevents ugly things
# when unicode escapes are split across substrings.
# Unquotes strings are collected token by token, so escape processing
# can only be done on the complete string (on output).

ADJUST {
    $content = $self->unescape($content) if defined($quote);
};

method append ($str) {
    $str = $self->unescape($str) if defined $quote;
    $content .= $str;
}

method content {
    defined($quote) ? $content : $self->unescape($content);
}

# One regexp to match them all...
my $esc_quoted = qr/
	       \\([tnrfb])				# $1 : one char
	     | \\u\{([[:xdigit:]]+)\}			# $2 : \u{XX...}
	     | \\u([Dd][89abAB][[:xdigit:]]{2})		# $3 : \uDXXX hi
	       \\u([Dd][c-fC-F][[:xdigit:]]{2})		# $4 : \uDXXX lo
	     | \\u([[:xdigit:]]{4})			# $5 : \uXXXX
	     | \\?(.)					# $6
	   /xs;

# Special escapes (quoted strings only).
my %esc = (
    'b'   => "\b",    #  Backspace
    'f'   => "\f",    #  Form feed
    'n'   => "\n",    #  New line
    'r'   => "\r",    #  Carriage return
    't'   => "\t",    #  Tab
    'v'   => chr(11), #  Vertical tab
);

method unescape ($str) {
    return $str unless $str =~ /\\/;

    my $convert = sub {
	# Specials. Only for quoted strings.
	if ( defined($1) ) {
	    return defined($quote) ? $esc{$1} : $1;
	}

	# Extended \u{XXX} character.
	defined($2) and return chr(hex($2));

	# Pair of surrogates.
	defined($3) and return pack( 'U*',
				     0x10000 + (hex($3) - 0xD800) * 0x400
				     + (hex($4) - 0xDC00) );

	# Standard \uXXXX character.
	defined($5) and return chr(hex($5));

	# Anything else.
	defined($6) and return $6;

	return '';
    };

    while( $str =~ s/\G$esc_quoted/$convert->()/gxse) {
        last unless defined pos($str);
    }

    return $str;
}

################ Quoted Strings ################

class JSON::Relaxed::String::Quoted :isa(JSON::Relaxed::String);

method as_perl( %options ) {
    $self->content;
}

method _data_printer( $ddp ) {
    "Token(" . $self->quote . $self->content . $self->quote . ", " .
      $self->type . ", " . $self->offset . ")";
}

################ Unquoted Strings ################

class JSON::Relaxed::String::Unquoted :isa(JSON::Relaxed::String);

# If the option always_string is set, bypass the reserved strings.
# This is used for hash keys.
method as_perl( %options ) {
    my $content = $self->content;

    # If used as a key, always return a string.
    return $content if $options{always_string};

    # Return boolean specials if appropriate.
    if ( $content =~ /^(?:true|false)$/ ) {
	return $self->parent->booleans->[ $content eq 'true' ? 1 : 0 ];
    }
    if ( $self->parent->prp && $content =~ /^(?:on|off)$/ ) {
	return $self->parent->booleans->[ $content eq 'on' ? 1 : 0 ];
    }

    # null -> undef
    elsif ( $content eq "null" ) {
	return;
    }

    # Return as string.
    $content;
}

method _data_printer( $ddp ) {
    "Token(«" . $self->content . "», " .
      $self->type . ", " . $self->offset . ")";
}

################ Booleans ################

# This class distinguises booleans true and false from numeric 1 and 0.

use JSON::PP ();

package JSON::Boolean {

    sub as_perl( $self, %options ) { $self }

    sub _data_printer( $self, $ddp ) { "Bool($self)" }

    use overload '""'     => sub { ${$_[0]} ? "true" : "false" },
		 "0+"     => sub { ${$_[0]} },
		 "bool"   => sub { !!${$_[0]} },
		 fallback => 1;

    # For JSON::PP export.
    sub TO_JSON { ${$_[0]} ? $JSON::PP::true : $JSON::PP::false }

    # Boolean values.
    our $true  = do { bless \(my $dummy = 1) => __PACKAGE__ };
    our $false = do { bless \(my $dummy = 0) => __PACKAGE__ };

}

################

1;
