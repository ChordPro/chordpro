package JSON::Relaxed;
use strict;

# debug tools
# use Debug::ShowStuff ':all';
# use Debug::ShowStuff::ShowVar;

# version
our $VERSION = '0.05';

# global error messages
our $err_id;
our $err_msg;


#------------------------------------------------------------------------------
# POD
#

=head1 NAME

JSON::Relaxed -- An extension of JSON that allows for better human-readability.

=head1 SYNOPSIS

 my ($rjson, $hash, $parser);
 
 # raw RJSON code
 $rjson = <<'(RAW)';
 /* Javascript-like comments are allowed */
 {
   // single or double quotes allowed
   a : 'Larry',
   b : "Curly",
   
   // nested structures allowed like in JSON
   c: [
      {a:1, b:2},
   ],
   
   // like Perl, trailing commas are allowed
   d: "more stuff",
 }
 (RAW)
 
 # subroutine parsing
 $hash = from_rjson($rjson);
 
 # object-oriented parsing
 $parser = JSON::Relaxed::Parser->new();
 $hash = $parser->parse($rjson);


=head1 INSTALLATION

JSON::Relaxed can be installed with the usual routine:

 perl Makefile.PL
 make
 make test
 make install

=head1 DESCRIPTION

JSON::Relaxed is a lightweight parser and serializer for an extension of JSON
called Relaxed JSON (RJSON).  The intent of RJSON is to provide a format that
is more human-readable and human-editable than JSON. Most notably, RJSON allows
the use of JavaScript-like comments. By doing so, configuration files and other
human-edited files can include comments to indicate the intention of each
configuration.

JSON::Relaxed is currently only a parser that reads in RJSON code and produces
a data structure. JSON::Relaxed does not currently encode data structures into
JSON/RJSON. That feature is planned.

=head2 Why Relaxed JSON?

There's been increasing support for the idea of expanding JSON to improve
human-readability.  "Relaxed" JSON is a term that has been used to describe a
JSON-ish format that has some features that JSON doesn't.  Although there isn't
yet any kind of official specification, descriptions of Relaxed JSON generally
include the following extensions to JSON:

=over 4

=item * comments

RJSON supports JavaScript-like comments:

 /* inline comments */
 // line-based comments

=item * trailing commas

Like Perl, RJSON allows treats commas as separators.  If nothing is before,
after, or between commas, those commas are just ignored:

 [
    , // nothing before this comma
    "data",
    , // nothing after this comma
 ]

=item * single quotes, double quotes, no quotes

Strings can be quoted with either single or double quotes.  Space-less strings
are also parsed as strings. So, the following data items are equivalent:

 [
    "Starflower",
    'Starflower',
    Starflower
 ]

Note that unquoted boolean values are still treated as boolean values, so the
following are NOT the same:

 [
    "true",  // string
    true,    // boolean true
    
    "false", // string
    false,   // boolean false
    
    "null", // string
    null, // what Perl programmers call undef
 ]

Because of this ambiguity, unquoted non-boolean strings should be considered
sloppy and not something you do in polite company.

=item * documents that are just a single string

Early versions of JSON require that a JSON document contains either a single
hash or a single array.  Later versions also allow a single string.  RJSON
follows that later rule, so the following is a valid RJSON document:

 "Hello world"

=item * hash keys without values

A hash in JSON can have a key that is followed by a comma or a closing C<}>
without a specified value.  In that case the hash element is simply assigned
the undefined value.  So, in the following example, C<a> is assigned C<1>,
C<b> is assigned 2, and C<c> is assigned undef:

 {
    a: 1,
    b: 2,
    c
 }

=back

=cut

#
# POD
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# from_rjson
#

=head2 from_rjson()

C<from_rjson()> is the simple way to quickly parse an RJSON string. Currently
C<from_rjson()> only takes a single parameter, the string itself. So in the
following example, C<from_rjson()> parses and returns the structure defined in
C<$rjson>.

 $structure = from_rjson($rjson);

=cut

sub from_rjson {
	my ($raw) = @_;
	my $parser = JSON::Relaxed::Parser->new();
	return $parser->parse($raw);
}
#
# from_rjson
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# object-oriented parsing
#

=head2 Object-oriented parsing

To parse using an object, create a C<JSON::Relaxed::Parser> object, like this:

 $parser = JSON::Relaxed::Parser->new();

Then call the parser's <code>parse</code> method, passing in the RJSON string:

 $structure = $parser->parse($rjson);

B<Methods>

=over 4

=item * $parser->extra_tokens_ok()

C<extra_tokens_ok()> sets/gets the C<extra_tokens_ok> property. By default,
C<extra_tokens_ok> is false.  If by C<extra_tokens_ok> is true then the
C<multiple-structures> isn't triggered and the parser returns the first
structure it finds.  So, for example, the following code would return undef and
sets the C<multiple-structures> error:

 $parser = JSON::Relaxed::Parser->new();
 $structure = $parser->parse('{"x":1} []');

However, by setting C<multiple-structures> to true, a hash structure is
returned, the extra code after that first hash is ignored, and no error is set:

 $parser = JSON::Relaxed::Parser->new();
 $parser->extra_tokens_ok(1);
 $structure = $parser->parse('{"x":1} []');

=back

=cut

#
# object-oriented parsing
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# error codes
#

=head2 Error codes

When JSON::Relaxed encounters a parsing error it returns C<undef> and sets two
global variables: 

=over 4

=item * $JSON::Relaxed::err_id

C<$err_id> is a unique code for a specific error.  Every code is set in only
one place in JSON::Relaxed.

=item * $JSON::Relaxed::err_msg

C<$err_msg> is an English description of the code.  It would be cool to migrate
towards multi-language support for C<$err_msg>.

=back

Following is a list of all error codes in JSON::Relaxed:

=over 4

=item * C<missing-parameter>

The string to be parsed was not sent to $parser->parse(). For example:

 $parser->parse()

=item * C<undefined-input>

The string to be parsed is undefined. For example:

 $parser->parse(undef)

=item * C<zero-length-input>

The string to be parsed is zero-length. For example:

 $parser->parse('')

=item * C<space-only-input>

The string to be parsed has no content beside space characters. For example:

 $parser->parse('   ')

=item * C<no-content>

The string to be parsed has no content. This error is slightly different than
C<space-only-input> in that it is triggered when the input contains only
comments, like this:

 $parser->parse('/* whatever */')


=item * C<unclosed-inline-comment>

A comment was started with /* but was never closed. For example:

 $parser->parse('/*')

=item * C<invalid-structure-opening-character>

The document opens with an invalid structural character like a comma or colon.
The following examples would trigger this error.

 $parser->parse(':')
 $parser->parse(',')
 $parser->parse('}')
 $parser->parse(']')

=item * C<multiple-structures>

The document has multiple structures. JSON and RJSON only allow a document to
consist of a single hash, a single array, or a single string. The following
examples would trigger this error.

 $parse->parse('{}[]')
 $parse->parse('{} "whatever"')
 $parse->parse('"abc" "def"')

=item * C<unknown-token-after-key>

A hash key may only be followed by the closing hash brace or a colon. Anything
else triggers C<unknown-token-after-key>. So, the following examples would
trigger this error.

 $parse->parse("{a [ }") }
 $parse->parse("{a b") }

=item * C<unknown-token-for-hash-key>

The parser encountered something besides a string where a hash key should be.
The following are examples of code that would trigger this error.

 $parse->parse('{{}}')
 $parse->parse('{[]}')
 $parse->parse('{]}')
 $parse->parse('{:}')

=item * C<unclosed-hash-brace>

A hash has an opening brace but no closing brace. For example:

 $parse->parse('{x:1')

=item * C<unclosed-array-brace>

An array has an opening brace but not a closing brace. For example:

 $parse->parse('["x", "y"')

=item * C<unexpected-token-after-colon>

In a hash, a colon must be followed by a value. Anything else triggers this
error. For example:

 $parse->parse('{"a":,}')
 $parse->parse('{"a":}')

=item * C<missing-comma-between-array-elements>

In an array, a comma must be followed by a value, another comma, or the closing
array brace.  Anything else triggers this error. For example:

 $parse->parse('[ "x" "y" ]')
 $parse->parse('[ "x" : ]')

=item * C<unknown-array-token>

This error exists just in case there's an invalid token in an array that
somehow wasn't caught by C<missing-comma-between-array-elements>. This error
shouldn't ever be triggered.  If it is please L<let me know|/AUTHOR>.

=item * C<unclosed-quote>

This error is triggered when a quote isn't closed. For example:

 $parse->parse("'whatever")
 $parse->parse('"whatever') }

=back


=cut

#
# error codes
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# export
#
use base 'Exporter';
use vars qw[@EXPORT_OK %EXPORT_TAGS];
push @EXPORT_OK, 'from_rjson';
%EXPORT_TAGS = ('all' => [@EXPORT_OK]);
#
# export
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# JSON::Relaxed POD
#

=head1 INTERNALS

The following documentation is for if you want to edit the code of
JSON::Relaxed itself.

=head2 JSON::Relaxed

C<JSON::Relaxed> is the parent package. Not a lot actually happens in
C<JSON::Relaxed>, it mostly contains L<from_rjson()|/from_rjson()> and
definitions of various structures.

=over 4

=cut

#
# JSON::Relaxed POD
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# special character and string definitions
#

=item Special character and string definitions

The following hashes provide information about characters and strings that have
special meaning in RJSON.

=over 4

=item * Escape characters

The C<%esc> hash defines the six escape characters in RJSON that are
changed to single characters. C<%esc> is defined as follows.

 our %esc = (
   'b'   => "\b",    #  Backspace
   'f'   => "\f",    #  Form feed
   'n'   => "\n",    #  New line
   'r'   => "\r",    #  Carriage return
   't'   => "\t",    #  Tab
   'v'   => chr(11), #  Vertical tab
 );

=cut

# escape characters
our %esc = (
	'b'   => "\b",    #  Backspace
	'f'   => "\f",    #  Form feed
	'n'   => "\n",    #  New line
	'r'   => "\r",    #  Carriage return
	't'   => "\t",    #  Tab
	'v'   => chr(11), #  Vertical tab
);

=item * Structural characters

The C<%structural> hash defines the six characters in RJSON that define
the structure of the data object. The structural characters are defined as
follows.

 our %structural = (
   '[' => 1, # beginning of array
   ']' => 1, # end of array
   '{' => 1, # beginning of hash
   '}' => 1, # end of hash
   ':' => 1, # delimiter between name and value of hash element
   ',' => 1, # separator between elements in hashes and arrays
 );

=cut

# structural
our %structural = (
	'[' => 1, # beginning of array
	']' => 1, # end of array
	'{' => 1, # beginning of hash
	'}' => 1, # end of hash
	':' => 1, # delimiter between name and value of hash element
	',' => 1, # separator between elements in hashes and arrays
);

=item * Quotes

The C<%quotes> hash defines the two types of quotes recognized by RJSON: single
and double quotes. JSON only allows the use of double quotes to define strings.
Relaxed also allows single quotes.  C<%quotes> is defined as follows.

 our %quotes = (
   '"' => 1,
   "'" => 1,
 );

=cut

# quotes
our %quotes = (
	'"' => 1,
	"'" => 1,
);

=item * End of line characters

The C<%newlines> hash defines the three ways a line can end in a RJSON
document. Lines in Windows text files end with carriage-return newline
("\r\n").  Lines in Unixish text files end with newline ("\n"). Lines in some
operating systems end with just carriage returns ("\n"). C<%newlines> is
defined as follows.

 our %newlines = (
   "\r\n" => 1,
   "\r" => 1,
   "\n" => 1,
 );

=cut

# newline tokens
our %newlines = (
	"\r\n" => 1,
	"\r" => 1,
	"\n" => 1,
);

=item * Boolean

The C<%boolean> hash defines strings that are boolean values: true, false, and
null. (OK, 'null' isn't B<just> a boolean value, but I couldn't think of what
else to call this hash.) C<%boolean> is defined as follows.

 our %boolean = (
   'null' => 1,
   'true' => 1,
   'false' => 1,
 );

=back

=cut

# boolean values
our %boolean = (
	'null' => undef,
	'true' => 1,
	'false' => 0,
);

#
# special character definitions
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# closing POD for JSON::Relaxed
#

=back

=cut

#
# closing POD for JSON::Relaxed
#------------------------------------------------------------------------------


###############################################################################
# JSON::Relaxed::Parser
#
package JSON::Relaxed::Parser;
use strict;


# debugging
# use Debug::ShowStuff ':all';


#------------------------------------------------------------------------------
# POD
#

=head2 JSON::Relaxed::Parser

A C<JSON::Relaxed::Parser> object parses the raw RJSON string. You don't
need to instantiate a parser if you just want to use the default settings.
In that case just use L<from_rjson()|/from_rjson()>.

You would create a C<JSON::Relaxed::Parser> object if you want to customize how
the string is parsed.  I say "would" because there isn't actually any
customization in these early releases. When there is you'll use a parser
object.

To parse in an object oriented manner, create the parser, then parse.

 $parser = JSON::Relaxed::Parser->new();
 $structure = $parser->parse($string);

=over 4

=cut

#
# POD
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# new
#

=item new

C<JSON::Relaxed::Parser->new()> creates a parser object. Its simplest and most
common use is without any parameters.

 my $parser = JSON::Relaxed::Parser->new();

=over 4

=item B<option:> unknown

The C<unknown> option sets the character which creates the
L<unknown object|/"JSON::Relaxed::Parser::Token::Unknown">. The unknown object
exists only for testing JSON::Relaxed. It has no purpose in production use.

 my $parser = JSON::Relaxed::Parser->new(unknown=>'~');

=back

=cut

sub new {
	my ($class, %opts) = @_;
	my $parser = bless({}, $class);
	
	# TESTING
	# println subname(); ##i
	
	# "unknown" object character
	if (defined $opts{'unknown'}) {
		$parser->{'unknown'} = $opts{'unknown'};
	}
	
	# return
	return $parser;
}
#
# new
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# extra_tokens_ok
#
sub extra_tokens_ok {
	my ($parser) = @_;
	
	# set value
	if (@_ > 1) {
		$parser->{'extra_tokens_ok'} = $_[1] ? 1 : 0;
	}
	
	# return
	return $parser->{'extra_tokens_ok'} ? 1 : 0;
}
#
# extra_tokens_ok
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# error
#
sub error {
	my ($parser, $id, $msg) = @_;
	
	# set errors
	$JSON::Relaxed::err_id = $id;
	$JSON::Relaxed::err_msg = $msg;
	
	# return undef
	return undef;
}
#
# error
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# is_error
#
sub is_error {
	my ($parser) = @_;
	
	# return true if there is an error, false otherwise
	if ($JSON::Relaxed::err_id)
		{ return 1 }
	else
		{ return 0 }
}
#
# is_error
#------------------------------------------------------------------------------




#------------------------------------------------------------------------------
# "is" methods
#

=item Parser "is" methods

The following methods indicate if a token has some specific property, such as
being a string object or a structural character.

=over 4

=cut



=item * is_string()

Returns true if the token is a string object, i.e. in the class
C<JSON::Relaxed::Parser::Token::String>.

=cut

# the object is a string object
sub is_string {
	my ($parser, $object) = @_;
	return UNIVERSAL::isa($object, 'JSON::Relaxed::Parser::Token::String');
}



=item * is_struct_char()

Returns true if the token is one of the structural characters of JSON, i.e.
one of the following:

 { } [ ] : ,

=cut

# the object is a structural character
sub is_struct_char {
	my ($parser, $object) = @_;
	
	# if it's a reference, it's not a structural character
	if (ref $object) {
		return 0;
	}
	
	# else if the object is defined
	elsif (defined $object) {
		return $JSON::Relaxed::structural{$object};
	}
	
	# else whatever it is it isn't a structural character
	else {
		return 0;
	}
}



=item * is_unknown_char()

Returns true if the token is the
L<unknown character|/"JSON::Relaxed::Parser::Token::Unknown">.

=cut

# the object is the "unknown" character
sub is_unknown_char {
	my ($parser, $char) = @_;
	
	# if there even is a "unknown" character
	if (defined $parser->{'unknown'}) {
		if ($char eq $parser->{'unknown'})
			{ return 1 }
	}
	
	# it's not the "unknown" character
	return 0;
}



=item * is_list_opener()

Returns true if the token is the opening character for a hash or an array,
i.e. it is one of the following two characters:

 { [

=cut

# is_list_opener
sub is_list_opener {
	my ($parser, $token) = @_;
	
	# if not defined, return false
	if (! defined $token)
		{ return 0 }
	
	# if it's an object, return false
	if (ref $token)
		{ return 0 }
	
	# opening brace for hash
	if ($token eq '{')
		{ return 1 }
	
	# opening brace for array
	if ($token eq '[')
		{ return 1 }
	
	# it's not a list opener
	return 0;
}


=item * is_comment_opener()

Returns true if the token is the opening character for a comment,
i.e. it is one of the following two couplets:

 /*
 //

=cut

# is_comment_opener
sub is_comment_opener {
	my ($parser, $token) = @_;
	
	# TESTING
	# println subname(); ##i
	
	# if not defined, return false
	if (! defined $token)
		{ return 0 }
	
	# if it's an object, return false
	if (ref $token)
		{ return 0 }
	
	# opening inline comment
	if ($token eq '/*')
		{ return 1 }
	
	# opening line comment
	if ($token eq '//')
		{ return 1 }
	
	# it's not a comment opener
	return 0;
}



=back

=cut

#
# "is" methods
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# parse
#

=item parse()

C<parse()> is the method that does the work of parsing the RJSON string.
It returns the data structure that is defined in the RJSON string.
A typical usage would be as follows.

 my $parser = JSON::Relaxed::Parser->new();
 my $structure = $parser->parse('["hello world"]');

C<parse()> does not take any options.

=cut

sub parse {
	my ($parser, $raw) = @_;
	my (@chars, @tokens, $rv);
	
	# TESTING
	# println subname(); ##i
	
	# clear global error information
	undef $JSON::Relaxed::err_id;
	undef $JSON::Relaxed::err_msg;
	
	# must have at least two params
	if (@_ < 2) {
		return $parser->error(
			'missing-parameter',
			'the string to be parsed was not sent to $parser->parse()'
		)
	}
	
	# $raw must be defined
	if (! defined $raw) {
		return $parser->error(
			'undefined-input',
			'the string to be parsed is undefined'
		);
	}
	
	# $raw must not be an empty string
	if ($raw eq '') {
		return $parser->error(
			'zero-length-input',
			'the string to be parsed is zero-length'
		);
	}
	
	# $raw must have content
	if ($raw !~ m|\S|s) {
		return $parser->error(
			'space-only-input',
			'the string to be parsed has no content beside space characters'
		);
	}
	
	# get characters
	@chars = $parser->parse_chars($raw);
	
	# get tokens
	@tokens = $parser->tokenize(\@chars);
	
	# special case: entire structure is a single scalar
	# NOTE: Some versions of JSON do not allow a single scalar as an entire
	# JSON document.
	#if (@tokens == 1) {
	#	# if single scalar is a string
	#	if ( $parser->is_string($tokens[0]) )
	#		{ return $tokens[0]->as_perl() }
	#}
	
	# must be at least one token
	if (! @tokens) {
		return $parser->error(
			'no-content',
			'the string to be parsed has no content'
		)
	}
	
	# build structure
	$rv = $parser->structure(\@tokens, top=>1);
}
#
# parse
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# parse_chars
#

=item parse_chars()

C<parse_chars()> parses the RJSON string into either individual characters
or two-character couplets. This method returns an array. The only input is the
raw RJSON string. So, for example, the following string:

 $raw = qq|/*x*/["y"]|;
 @chars = $parser->parse_chars($raw);

would be parsed into the following array:

 ( "/*", "x", "*/", "[", "\"", "y", "\""", "]" )

Most of the elements in the array are single characters. However, comment
delimiters, escaped characters, and Windows-style newlines are parsed as
two-character couplets:

=over 4

=item * C<\> followed by any character

=item * C<\r\n>

=item * C<//>

=item * C</*>

=item * C<*/>

=back

C<parse_chars()> should not produce any fatal errors.

=cut

sub parse_chars {
	my ($parser, $raw) = @_;
	my (@rv);
	
	# clear global error information
	undef $JSON::Relaxed::err_id;
	undef $JSON::Relaxed::err_msg;
	
	# split on any of the following couplets, or on single characters
	#   \{any character}
	#   \r\n
	#   //
	#   /*
	#   */
	#   {any character}
	@rv = split(m/(\\.|\r\n|\r|\n|\/\/|\/\*|\*\/|,|:|{|}|\[|\]|\s+|.)/sx, $raw);
	
	# remove empty strings
	@rv = grep {length($_)} @rv;
	
	# return
	return @rv;
}
#
# parse_chars
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# tokenize
#

=item tokenize()

C<tokenize()> organizes the characters from
C<L<parse_chars()|/"parse_chars()">> into tokens. Those tokens can then be
organized into a data structure with
C<L<structure()|/"structure()">>.

Each token represents an item that is recognized by JSON. Those items include
structural characters such as C<{> or C<}>, or strings such as
C<"hello world">. Comments and insignificant whitespace are filtered out
by C<tokenize()>.

For example, this code:

 $parser = JSON::Relaxed::Parser->new();
 $raw = qq|/*x*/ ["y"]|;
 @chars = $parser->parse_chars($raw);
 @tokens = $parser->tokenize(\@chars);

would produce an array like this:

 (
   '[',
   JSON::Relaxed::Parser::Token::String::Quoted=HASH(0x20bf0e8),
   ']'
 )

Strings are tokenized into string objects.  When the parsing is complete they
are returned as scalar variables, not objects.

C<tokenize()> should not produce any fatal errors.

=cut

sub tokenize {
	my ($parser, $chars_org) = @_;
	my (@chars, @tokens);
	
	# TESTING
	# println subname(); ##i
	
	# create own array of characters
	@chars = @$chars_org;
	
	# TESTING
	# println '[', join('] [', @chars), ']';
	
	# loop through characters
	CHAR_LOOP:
	while (@chars) {
		my $char = shift(@chars);
		
		# // - line comment
		# remove everything up to and including the end of line
		if ($char eq '//') {
			LINE_COMMENT_LOOP:
			while (@chars) {
				my $next = shift(@chars);
				
				# if character is any of the end of line strings
				if ($newlines{$next})
					{ last LINE_COMMENT_LOOP }
			}
		}
		
		# /* */ - inline comments
		# remove everything until */
		elsif ($char eq '/*') {
			INLINE_COMMENT_LOOP:
			while (@chars) {
				my $next = shift(@chars);
				
				# if character is any of the end of line strings
				if ($next eq '*/')
					{ next CHAR_LOOP }
			}
			
			# if we get this far then the comment was never closed
			return $parser->error(
				'unclosed-inline-comment',
				'a comment was started with /* but was never closed'
			);
		}
		
		# /* */ - inline comments
		# remove everything until */
		elsif ($char eq '/*') {
			INLINE_COMMENT_LOOP:
			while (@chars) {
				my $next = shift(@chars);
				
				# if character is any of the end of line strings
				if ($next eq '*/')
					{ last INLINE_COMMENT_LOOP }
			}
		}
		
		# white space: ignore
		elsif ($char =~ m|\s+|) {
		}
		
		# structural characters
		elsif ($JSON::Relaxed::structural{$char}) {
			push @tokens, $char;
		}
		
		# quotes
		# remove everything until next quote of same type
		elsif ($JSON::Relaxed::quotes{$char}) {
			my $str = JSON::Relaxed::Parser::Token::String::Quoted->new($parser, $char, \@chars);
			push @tokens, $str;
		}
		
		# "unknown" object string
		elsif ($parser->is_unknown_char($char)) {
			my $unknown = JSON::Relaxed::Parser::Token::Unknown->new($char);
			push @tokens, $unknown;
		}
		
		# else it's an unquoted string
		else {
			my $str = JSON::Relaxed::Parser::Token::String::Unquoted->new($parser, $char, \@chars);
			push @tokens, $str;
		}
	}
	
	# return tokens
	return @tokens;
}
#
# tokenize
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# structure
#

=item structure()

C<$parser->structure()> organizes the tokens from C<L<tokenize()|/"tokenize()">>
into a data structure.  C<$parser->structure()> returns a single string, single
array reference, a single hash reference, or (if there are errors) undef.

=cut

sub structure {
	my ($parser, $tokens, %opts) = @_;
	my ($rv, $opener);
	
	# TESTING
	# println subname(); ##i
	
	# get opening token
	if (defined $opts{'opener'})
		{ $opener = $opts{'opener'} }
	else
		{ $opener = shift(@$tokens) }
	
	# if no opener that's an error, so we're done
	if (! defined $opener)
		{ return undef }
	
	# string
	if ($parser->is_string($opener)) {
		$rv = $opener->as_perl();
	}
	
	# opening of hash
	elsif ($opener eq '{') {
		$rv = JSON::Relaxed::Parser::Structure::Hash->build($parser, $tokens);
	}
	
	# opening of array
	elsif ($opener eq '[') {
		$rv = JSON::Relaxed::Parser::Structure::Array->build($parser, $tokens);
	}
	
	# else invalid opening character
	else {
		return $parser->error(
			'invalid-structure-opening-character',
			'expected { or [ but got ' .
			$parser->invalid_token($opener) . ' ' .
			'instead'
		);
	}
	
	# If this is the outer structure, and there are any tokens left, then
	# that's a multiple structure document.  We don't allow that sort of thing
	# around here unless extra_tokens_ok is explicitly set to ok
	if ($opts{'top'}) {
		if (! $parser->is_error) {
			if (@$tokens) {
				unless ($parser->extra_tokens_ok()) {
					return $parser->error(
						'multiple-structures',
						'the string being parsed contains two separate structures, only one is allowed'
					);
				}
			}
		}
	}
	
	# return
	return $rv;
}
#
# structure
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# invalid_token
#
sub invalid_token {
	my ($parser, $token) = @_;
	
	# string
	if ($parser->is_string($token)) {
		return 'string';
	}
	
	# object
	elsif (ref $token) {
		return ref($token) . ' object';
	}
	
	# scalar
	else {
		return $token;
	}
}
#
# invalid_token
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# closing POD
#

=back

=cut

#
# closing POD
#------------------------------------------------------------------------------


#
# JSON::Relaxed::Parser
###############################################################################



###############################################################################
# JSON::Relaxed::Parser::Structure::Hash
#
package JSON::Relaxed::Parser::Structure::Hash;
use strict;

# debugging
# use Debug::ShowStuff ':all';


#------------------------------------------------------------------------------
# POD
#

=head2 JSON::Relaxed::Parser::Structure::Hash

This package parses Relaxed into hash structures. It is a static package, i.e.
it is not instantiated.

=over 4

=cut

#
# POD
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# build
#

=item build()

This static method accepts the array of tokens and works through them building
the hash reference that they represent. When C<build()> reaches the closing
curly brace (C<}>) it returns the hash reference.

=cut

sub build {
	my ($class, $parser, $tokens) = @_;
	my $rv = {};
	
	# TESTING
	# println subname(); ##i
	
	# build hash
	# work through tokens until closing brace
	TOKENLOOP:
	while (@$tokens) {
		my $next = shift(@$tokens);
		# what is allowed after opening brace:
		#	closing brace
		#	comma
		#	string
		
		# if closing brace, return
		if ($next eq '}') {
			return $rv;
		}
		
		# if comma, do nothing
		elsif ($next eq ',') {
		}
		
		# string
		# If the token is a string then it is a key. The token after that
		# should be a value.
		elsif ( $parser->is_string($next) ) {
			my ($key, $value, $t0);
			$t0 = $tokens->[0];
			
			# set key using string
			$key = $next->as_perl(always_string=>1);
			
			# if anything follows the string
			if (defined $t0) {
				# if next token is a colon then it should be followed by a value
				if ( $t0 eq ':' ) {
					# remove the colon
					shift(@$tokens);
					
					# if at end of token array, exit loop
					@$tokens or last TOKENLOOP;
					
					# get hash value
					$value = $class->get_value($parser, $tokens);
					
					# if there is a global error, return undef
					$parser->is_error() and return undef;
				}
				
				# a comma or closing brace is acceptable after a string
				elsif ($t0 eq ',') {
				}
				elsif ($t0 eq '}') {
				}
				
				# anything else is an error
				else {
					return $parser->error(
						'unknown-token-after-key',
						'expected comma or closing brace after a ' .
						'hash key, but got ' .
						$parser->invalid_token($t0) . ' ' .
						'instead'
					);
				}
			}
			
			# else nothing followed the string, so break out of token loop
			else {
				last TOKENLOOP;
			}
			
			# set key and value in return hash
			$rv->{$key} = $value;
		}
		
		# anything else is an error
		else {
			return $parser->error(
				'unknown-token-for-hash-key',
				'expected string, comma, or closing brace in a ' .
				'hash key, but got ' .
				$parser->invalid_token($next) . ' ' .
				'instead'
			);
		}
	}
	
	# if we get this far then unclosed brace
	return $parser->error(
		'unclosed-hash-brace',
		'do not find closing brace for hash'
	);
}
#
# build
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# get_value
#

=item get_value

This static method gets the value of a hash element. This method is called
after a hash key is followed by a colon. A colon must be followed by a value.
It may not be followed by the end of the tokens, a comma, or a closing brace.

=cut

sub get_value {
	my ($class, $parser, $tokens) = @_;
	my ($next);
	
	# TESTING
	# println subname(); ##i
	
	# get next token
	$next = shift(@$tokens);
	
	# next token must be string, array, or hash
	# string
	if ($parser->is_string($next)) {
		return $next->as_perl();
	}
	
	# token opens a hash
	elsif ($parser->is_list_opener($next)) {
		return $parser->structure($tokens, opener=>$next);
	}
	
	# at this point it's an illegal token
	return $parser->error(
		'unexpected-token-after-colon',
		'expected a value after a colon in a hash, got ' .
		$parser->invalid_token($next) . ' ' .
		'instead'
	);
}
#
# get_value
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# closing POD
#

=back

=cut

#
# closing POD
#------------------------------------------------------------------------------


#
# JSON::Relaxed::Parser::Structure::Hash
###############################################################################


###############################################################################
# JSON::Relaxed::Parser::Structure::Array
#
package JSON::Relaxed::Parser::Structure::Array;
use strict;

# debugging
# use Debug::ShowStuff ':all';


#------------------------------------------------------------------------------
# POD
#

=head2 JSON::Relaxed::Parser::Structure::Array

This package parses Relaxed into array structures. It is a static package, i.e.
it is not instantiated.

=over 4

=cut

#
# POD
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# build
#

=item build()

This static method accepts the array of tokens and works through them building
the array reference that they represent. When C<build()> reaches the closing
square brace (C<]>) it returns the array reference.

=cut

sub build {
	my ($class, $parser, $tokens) = @_;
	my $rv = [];
	
	# TESTING
	# println subname(); ##i
	
	# build array
	# work through tokens until closing brace
	while (@$tokens) {
		my $next = shift(@$tokens);
		
		# closing brace: we're done building this array
		if ($next eq ']') {
			return $rv;
		}
		
		# opening of hash or array
		elsif ($parser->is_list_opener($next)) {
			my $object = $parser->structure($tokens, opener=>$next);
			defined($object) or return undef;
			push @$rv, $object;
		}
		
		# comma: if we get to a comma at this point, do nothing with it
		elsif ($next eq ',') {
		}
		
		# if string, add it to the array
		elsif ($parser->is_string($next)) {
			# add the string to the array
			push @$rv, $next->as_perl();
			
			# check following token, which must be either a comma or
			# the closing brace
			if (@$tokens) {
				my $n2 = $tokens->[0] || '';
				
				# the next element must be a comma or the closing brace,
				# anything else is an error
				unless  ( ($n2 eq ',') || ($n2 eq ']') ) {
					return missing_comma($parser, $n2);
				}
			}
		}
		
		# else unkown object or character, so throw error
		else {
			return invalid_array_token($parser, $next);
		}
	}
	
	# if we get this far then unclosed brace
	return $parser->error(
		'unclosed-array-brace',
		'do not find closing brace for array'
	);
}
#
# build
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# missing_comma
#

=item missing_comma()

This static method build the C<missing-comma-between-array-elements> error
message.

=cut

sub missing_comma {
	my ($parser, $token) = @_;
	
	# initialize error message
	return $parser->error(
		'missing-comma-between-array-elements',
		'expected comma or closing array brace, got ' .
		$parser->invalid_token($token) . ' ' .
		'instead'
	);
}
#
# missing_comma
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# invalid_array_token
#

=item invalid_array_token)

This static method build the C<unknown-array-token> error message.

=cut

sub invalid_array_token {
	my ($parser, $token) = @_;
	
	# initialize error message
	return $parser->error(
		'unknown-array-token',
		'unexpected item in array: got ' .
		$parser->invalid_token($token)
	);
}
#
# invalid_array_token
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# closing POD
#

=back

=cut

#
# closing POD
#------------------------------------------------------------------------------



#
# JSON::Relaxed::Parser::Structure::Array
###############################################################################



###############################################################################
# JSON::Relaxed::Parser::Token::String::Quoted
#
package JSON::Relaxed::Parser::Token::String;
use strict;

# debugging
# use Debug::ShowStuff ':all';


#------------------------------------------------------------------------------
# POD
#

=head2 JSON::Relaxed::Parser::Token::String

Base class . Nothing actually happens in this package, it's just a base class
for JSON::Relaxed::Parser::Token::String::Quoted and
JSON::Relaxed::Parser::Token::String::Unquoted.

=cut

#
# POD
#------------------------------------------------------------------------------


#
# JSON::Relaxed::Parser::Token::String
###############################################################################



###############################################################################
# JSON::Relaxed::Parser::Token::String::Quoted
#
package JSON::Relaxed::Parser::Token::String::Quoted;
use strict;
use base 'JSON::Relaxed::Parser::Token::String';

# debugging
# use Debug::ShowStuff ':all';


#------------------------------------------------------------------------------
# POD
#

=head2 JSON::Relaxed::Parser::Token::String::Quoted

A C<JSON::Relaxed::Parser::Token::String::Quoted> object represents a string
in the document that is delimited with single or double quotes.  In the
following example, I<Larry> and I<Curly> would be represented by C<Quoted>
objects by I<Moe> would not.

 [
    "Larry",
    'Curly',
    Moe
 ]

C<Quoted> objects are created by C<$parser-E<gt>tokenize()> when it works
through the array of characters in the document.

=over 4

=cut

#
# POD
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# new
#

=item * C<new()>

C<new()> instantiates a C<JSON::Relaxed::Parser::Token::String::Quoted> object
and slurps in all the characters in the characters array until it gets to the
closing quote.  Then it returns the new C<Quoted> object.

A C<Quoted> object has the following two properties:

C<raw>: the string that is inside the quotes.  If the string contained any
escape characters then the escapes are processed and the unescaped characters
are in C<raw>. So, for example, C<\n> would become an actual newline.

C<quote>: the delimiting quote, i.e. either a single quote or a double quote.


=cut

sub new {
	my ($class, $parser, $quote, $chars) = @_;
	my $str = bless({}, $class);
	
	# TESTING
	# println subname(); ##i
	
	# initialize hash
	$str->{'quote'} = $quote;
	$str->{'raw'} = '';
	
	# loop through remaining characters until we find another quote
	CHAR_LOOP:
	while (@$chars) {
		my $next = shift(@$chars);
		
		# if this is the matching quote, we're done
		if ($next eq $str->{'quote'})
			{ return $str }
		
		# if leading slash, check if it's a special escape character
		if ($next =~ s|^\\(.)|$1|s) {
			if ($JSON::Relaxed::esc{$next})
				{ $next = $JSON::Relaxed::esc{$next} }
		}
		
		# add to raw
		$str->{'raw'} .= $next;
	}
	
	# if we get this far then we never found the closing quote
	return $parser->error(
		'unclosed-quote',
		'string does not have closing quote before end of file'
	);
}
#
# new
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# as_perl
#

=item * C<as_perl()>

C<as_perl()> returns the string that was in quotes (without the quotes).

=cut

sub as_perl {
	my ($str) = @_;
	return $str->{'raw'};
}
#
# as_perl
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# close POD item list
#

=back

=cut

#
# close POD item list
#------------------------------------------------------------------------------


#
# JSON::Relaxed::Parser::Token::String::Quoted
###############################################################################


###############################################################################
# JSON::Relaxed::Parser::Token::String::Unquoted
#
package JSON::Relaxed::Parser::Token::String::Unquoted;
use strict;
use base 'JSON::Relaxed::Parser::Token::String';

# debugging
# use Debug::ShowStuff ':all';




#------------------------------------------------------------------------------
# POD
#

=head2 JSON::Relaxed::Parser::Token::String::Unquoted

A C<JSON::Relaxed::Parser::Token::String::Unquoted> object represents a string
in the document that was not delimited quotes.  In the following example,
I<Moe> would be represented by an C<Unquoted> object, but I<Larry> and I<Curly>
would not.

 [
    "Larry",
    'Curly',
    Moe
 ]

C<Unquoted> objects are created by C<$parser-E<gt>tokenize()> when it works
through the array of characters in the document.

An C<Unquoted> object has one property, C<raw>, which is the string. Escaped
characters are resolved in C<raw>.

=over 4

=cut

#
# POD
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# new
#

=item * C<new()>

C<new()> instantiates a C<JSON::Relaxed::Parser::Token::String::Unquoted>
object and slurps in all the characters in the characters array until it gets
to a space character, a comment, or one of the structural characters such as
C<{> or C<:>.

=cut

sub new {
	my ($class, $parser, $char, $chars) = @_;
	my $str = bless({}, $class);
	
	# TESTING
	# println subname(); ##i
	
	# initialize hash
	$str->{'raw'} = $char;
	
	# loop while not space or structural characters
	TOKEN_LOOP:
	while (@$chars) {
		# if structural character, we're done
		if ($JSON::Relaxed::structural{$chars->[0]})
			{ last TOKEN_LOOP }
		
		# if space character, we're done
		if ($chars->[0] =~ m|\s+|s)
			{ last TOKEN_LOOP }
		
		# if opening of a comment, we're done
		if ($parser->is_comment_opener($chars->[0]))
			{ last TOKEN_LOOP }
		
		# add to raw string
		$str->{'raw'} .= shift(@$chars);
	}
	
	# return
	return $str;
}
#
# new
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# as_perl
#

=item * C<as_perl()>

C<as_perl()> returns the unquoted string or a boolean value, depending on how
it is called.

If the string is a boolean value, i.e. I<true>, I<false>, then the C<as_perl>
return 1 (for true), 0 (for false) or undef (for null), B<unless> the
C<always_string> option is sent, in which case the string itself is returned.
If the string does not represent a boolean value then it is returned as-is.

C<$parser-E<gt>structure()> sends the C<always_string> when the token is a key
in a hash. The following example should clarify how C<always_string> is used:

 {
    // key: the literal string "larry"
    // value: 1
    larry : true,
    
    // key: the literal string "true"
    // value: 'x'
    true : 'x',
    
    // key: the literal string "null"
    // value: 'y'
    null : 'y',
    
    // key: the literal string "z"
    // value: undef
    z : null,
 }

=cut

sub as_perl {
	my ($str, %opts) = @_;
	my $rv = $str->{'raw'};
	
	# if string is one of the unquoted boolean values
	# unless options indicate to always return the value as a string, check it
	# the value is one of the boolean string
	unless ($opts{'always_string'}) {
		if (exists $JSON::Relaxed::boolean{lc $rv}) {
			$rv = $JSON::Relaxed::boolean{lc $rv};
		}
	}
	
	# return
	return $rv;
}
#
# as_perl
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# close POD item list
#

=back

=cut

#
# close POD item list
#------------------------------------------------------------------------------


#
# JSON::Relaxed::Parser::Token::String::Unquoted
###############################################################################


###############################################################################
# JSON::Relaxed::Parser::Token::Unknown
#
package JSON::Relaxed::Parser::Token::Unknown;
use strict;

#------------------------------------------------------------------------------
# POD
#

=head2 JSON::Relaxed::Parser::Token::Unknown

This class is just used for development of JSON::Relaxed. It has no use in
production. This class allows testing for when a token is an unknown object.

To implement this class, add the 'unknown' option to JSON::Relaxed->new(). The
value of the option should be the character that creates an unknown object.
For example, the following option sets the tilde (~) as an unknown object.

 my $parser = JSON::Relaxed::Parser->new(unknown=>'~');

The "unknown" character must not be inside quotes or inside an unquoted string.

=cut

#
# POD
#------------------------------------------------------------------------------




#------------------------------------------------------------------------------
# new
#
sub new {
	my ($class, $char) = @_;
	my $unknown = bless({}, $class);
	$unknown->{'raw'} = $char;
	return $unknown;
}
#
# new
#------------------------------------------------------------------------------

#
# JSON::Relaxed::Parser::Token::Unknown
###############################################################################


# return true
1;


__END__

=head1 TERMS AND CONDITIONS

Copyright (c) 2014 by Miko O'Sullivan.  All rights reserved.  This program is 
free software; you can redistribute it and/or modify it under the same terms 
as Perl itself. This software comes with B<NO WARRANTY> of any kind.

=head1 AUTHOR

Miko O'Sullivan
F<miko@idocs.com>

=head1 VERSION

Version: 0.04

=head1 HISTORY

=over 4

=item Version 0.01    Nov 30, 2014

Initial version.

=item Version 0.02    Dec 3, 2014

Fixed test.t so that it can load lib.pm when it runs.

Added $parser->extra_tokens_ok(). Removed error code
C<invalid-structure-opening-string> and allowed that error to fall through to
C<multiple-structures>.

Cleaned up documentation.

=item Version 0.03    Dec 6, 2014

Modified test for parse_chars to normalize newlines.  Apparently the way Perl
on Windows handles newline is different than what I expected, but as long as
it's recognizing newlines and|or carriage returns then the test should pass.

=item Version 0.04 Apr 28, 2016

Fixed bug in which end of line did not terminate some line comments.

Minor cleanups of documentation.

Cleaned up test.pl.

=item Version 0.05 Apr 30, 2016

Fixed bug: Test::Most was not added to the prerequisite list. No changes
to the functionality of the module itself.

=back


=cut

#------------------------------------------------------------------------------
# module info
#
{
	# include in CPAN distribution
	include : 1,
	
	# allow modules
	allow_modules : {
	},
	
	# test scripts
	test_scripts : {
		'Relaxed/tests/test.pl' : 1,
	},
}
#
# module info
#------------------------------------------------------------------------------
