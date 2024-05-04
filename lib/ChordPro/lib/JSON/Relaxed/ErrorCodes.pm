#! perl

use v5.26;
use utf8;

package  JSON::Relaxed::ErrorCodes;

use JSON::Relaxed::Parser; our $VERSION = $JSON::Relaxed::Parser::VERSION;

=head1 JSON::Relaxed::ErrorCodes -- Error messages

If the document cannot be parsed, JSON::Relaxed will normally throw an
exception.

In legacy mode, JSON::Relaxed returns an undefined
value instead and sets the following error indicators:

=over 4

=item * $JSON::Relaxed::err_id

A unique code for a specific error.

=item * $JSON::Relaxed::err_msg

An English description of the error, including an indication where the
error occurs.

=back

When using object-oriented mode, these can be easily retrieved using
the parser methods err_id() and err_msg().

Following is a list of all error codes in JSON::Relaxed:

=over 4

=item * C<missing-input>

No input was found. This can be caused by:

    $parser->decode()
    $parser->decode(undef)

=item * C<empty-input>

The string to be parsed has no content beside whitespace and comments.

    $parser->decode('')
    $parser->decode('   ')
    $parser->decode('/* whatever */')

=item * C<unclosed-inline-comment>

A comment was started with /* but was never closed. For example:

    $parser->decode('/*')

=item * C<invalid-structure-opening-character>

The document opens with an invalid structural character like a comma or colon.
The following examples would trigger this error.

    $parser->decode(':')
    $parser->decode(',')
    $parser->decode('}')
    $parser->decode(']')

=item * C<multiple-structures>

The document has multiple structures. JSON and RJSON only allow a document to
consist of a single hash, a single array, or a single string. The following
examples would trigger this error.

    $parse->decode('{}[]')
    $parse->decode('{} "whatever"')
    $parse->decode('"abc" "def"')

=item * C<unknown-token-after-key>

A hash key may only be followed by the closing hash brace or a colon. Anything
else triggers C<unknown-token-after-key>. So, the following examples would
trigger this error.

    $parse->decode("{a [ }") }
    $parse->decode("{a b") }

=item * C<unknown-token-for-hash-key>

The parser encountered something besides a string where a hash key should be.
The following are examples of code that would trigger this error.

    $parse->decode('{{}}')
    $parse->decode('{[]}')
    $parse->decode('{]}')
    $parse->decode('{:}')

=item * C<unclosed-hash-brace>

A hash has an opening brace but no closing brace. For example:

    $parse->decode('{x:1')

=item * C<unclosed-array-brace>

An array has an opening brace but not a closing brace. For example:

    $parse->decode('["x", "y"')

=item * C<unexpected-token-after-colon>

In a hash, a colon must be followed by a value. Anything else triggers this
error. For example:

    $parse->decode('{"a":,}')
    $parse->decode('{"a":}')

=item * C<missing-comma-between-array-elements>

In an array, a comma must be followed by a value, another comma, or the closing
array brace.  Anything else triggers this error. For example:

    $parse->decode('[ "x" "y" ]')
    $parse->decode('[ "x" : ]')

=item * C<unknown-array-token>

This error exists just in case there's an invalid token in an array that
somehow wasn't caught by C<missing-comma-between-array-elements>. This error
shouldn't ever be triggered.  If it is please L<let me know|JSON::Relaxed/"AUTHOR">.

=item * C<unclosed-quote>

This error is triggered when a quote isn't closed. For example:

    $parse->decode("'whatever")
    $parse->decode('"whatever') }

=back

=cut

my %msg =
  ( 'missing-input' => 'the string to be parsed is empty or undefined',
    'unknown-array-token' => 'unexpected array token',
     'empty-input' =>
    'the string to be parsed has no content',
    'unclosed-inline-comment' =>
    'a comment was started with /* but was never closed',
    'invalid-structure-opening-character' =>
    'expected opening brace or opening bracket',
    'multiple-structures' =>
    'the string being parsed contains more than one structure',
    'unknown-token-after-key' =>
    'expected comma or closing brace after a hash key',
    'unknown-token-for-hash-key' =>
    'expected string, comma, or closing brace in a hash key',
    'unclosed-hash-brace' =>
    'missing closing brace for hash',
    'unclosed-array-brace' =>
    'missing closing brace for array',
    'unexpected-token-after-colon' =>
    'expected a value after a colon in a hash',
    'missing-comma-between-array-elements' =>
    'expected comma or closing array brace',
    'unknown-array-token' =>
    'unexpected token in array',
    'unclosed-quote' =>
    'missing closing quote for string'
  );

sub message {
    my ( $self, $id, $aux ) = @_;
    my $msg = $msg{$id} // ($id =~ s/-/ /gr);
    if ( $aux ) {
	$msg .= sprintf( ", at character offset %d (before %s)",
			 $aux->offset, $aux->as_string );
    }
    else {
	$msg .= ", at end of string";
    }
    $msg;
}

1;
