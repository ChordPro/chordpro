#! perl

use v5.26;
use utf8;

package JSON::Relaxed;

use JSON::Relaxed::Parser; our $VERSION = $JSON::Relaxed::Parser::VERSION;

=encoding UTF-8

=head1 NAME

JSON::Relaxed -- An extension of JSON that allows for better human-readability

=head1 Relaxed JSON?

There's been increasing support for the idea of expanding JSON to improve
human-readability.
"Relaxed" JSON (RJSON) is a term that has been used to describe a
JSON-ish format that has some human-friendly features that JSON doesn't.
Most notably, RJSON allows the use of JavaScript-like comments and
eliminates the need to quote all keys and values.
An (official) specification can be found on
L<RelaxedJSON.org|https://www.relaxedjson.org>.

I<Note that by definition every valid JSON document is also a valid
RJSON document.>

=head1 SYNOPSIS

    use JSON::Relaxed;

    # Some raw RJSON data.
    my $rjson = <<'RAW_DATA';
    /* Javascript-like comments. */
    {
        // Keys do not require quotes.
        // Single, double and backtick quotes.
        a : 'Larry',
        b : "Curly",
        c : `Phoey`,
        // Simple values do not require quotes.
        d:  unquoted

        // Nested structures.
        e: [
          { a:1, b:2 },
        ],

        // Like Perl, trailing commas are allowed.
        f: "more stuff",
    }
    RAW_DATA

    # Functional parsing.
    my $hash = decode_rjson($rjson);

    # Object-oriented parsing.
    my $parser = JSON::Relaxed->new();
    $hash = $parser->decode($rjson);

=head1 DESCRIPTION

JSON::Relaxed is a lightweight parser and serializer for RJSON.
It is fully compliant to the
L<RelaxedJSON.org|https://www.relaxedjson.org/specification> specification.

It does, however, have some additional extensions to make it really
relaxed.

=head1 LEGACY MODE

The old static method C<from_rjson> has been renamed to C<decode_rjson>,
to conform to many other modules of this kind.
For compatibility with pre-0.060 versions
C<from_rjson> is kept as a synonym for C<decode_rjson>.

For the same reason, the old parser method C<parse> has been renamed
to C<decode>.
For compatibility C<parse> is kept as a synonym for C<decode>.

When called by one of the old names, JSON::Relaxed will operate in
legacy mode. This changes the way errors are handled.

=head1 REALLY RELAXED EXTENSIONS

Extensions are disabled if option C<strict> is set.
Otherwise, most extensions are enabled by default.
Some extensions need an additional option setting.

=head2 Leading commas in lists

For example,

    [ , 1 ]

Enabled by default, overruled by C<strict>.

=head2 Hash keys without values

JSON::Relaxed supports object keys without a specified value.
In that case the hash element is simply assigned the undefined value.

In the following example, a is assigned 1, and b is assigned undef:

    { a:1, b }

Enabled by default, overruled by C<strict>.

=head2 String continuation

Long strings can be aesthetically split over multiple lines by putting
a backslash at the end of the line:

      "this is a " \
      "long string"

Note that this is different from

      "this is a \
    long string"

which B<embeds> the newline into the string, and requires continuation
lines to start at the beginning of the line to prevent unwanted spaces.

Enabled by default, overruled by C<strict>.

=head2 Extended Unicode escapes

Unicode escapes in strings may contain an arbitrary number of hexadecimal
digits enclosed in braces:

    \u{1d10e}

This eliminates the need to use
L<surrogates|https://unicode.org/faq/utf_bom.html#utf16-2>
to obtain the same character:

    \uD834\uDD0E

Enabled by default, overruled by C<strict>.

=head2 Combined hash keys

Hash keys that contain periods are considered subkeys, e.g.

    foo.bar: blech

is equivalent to

    foo: {
        bar: blech
    }

Requires C<combined_keys> or C<prp> option. Overruled by C<strict>.

=head2 Implied outer hash

If the JSON looks like a hash, i.e. a string (key) followed by a
C<:>, the outer C<{> and C<}> are implied.

For example:

    foo : bar

is equivalent to:

    { foo : bar }

Requires C<implied_outer_hash> or C<prp> option. Overruled by C<strict>.

=head2 Garbage after JSON structure

Requires C<extra_tokens_ok> option. Overruled by C<strict>.

Normally, parsing will fail unless the input contains exactly one
valid JSON structure, i.e. a string, a hash or an array.

With C<extra_tokens_ok> the first JSON structure is parsed and the
rest is ignored.

=head2 PRP extensions

Requires C<prp> option. Overruled by C<strict>.

Enables some specific extensions:

The equal sign C<=> can be used as an alternative to C<:> (colon).

Colon (and equal sign) is optional between a key and its hash value.

Single-line comments may start with C<#>.

For example:

    # This is a sample PRP extended Really Relaxed JSON.
    pdf.formats {
      title.footer = [ "%{copyright}" "" "%{page}" ]
      first.footer = [ "%{copyright}" "" "" ]
    }

This is equivalent to Really Relaxed JSON:

    // This is a sample Really Relaxed JSON.
    pdf.formats: {
      title.footer: [ "%{copyright}" "" "%{page}" ]
      first.footer: [ "%{copyright}" "" "" ]
    }

And Relaxed JSON:

    // This is a sample Relaxed JSON.
    {
      pdf: {
        formats: {
          title: {
            footer: [ "%{copyright}" "" "%{page}" ]
          }
          first: {
            footer: [ "%{copyright}" "" "" ]
          }
        }
      }
    }

And JSON:

    {
      "pdf" : {
        "formats" : {
          "title" : {
            "footer" : [ "%{copyright}", "", "%{page}" ]
          }
        },
        "first" : {
          "footer" : [ "%{copyright}", "", "" ]
          }
        }
      }
    }

You decide what is easiest to write ☺.

=head1 SUBROUTINES

=head2 decode_rjson

    $structure = decode_rjson( $data, %options )

C<decode_rjson()> is the simple way to parse an RJSON string.
It is exported by default.
C<decode_rjson> takes a single parameter, the string to be parsed.

Optionally an additional hash with options can be passed
to change the behaviour of the parser.
See L<below|"Object-oriented-parsing">.

    $structure = decode_rjson( $rjson, %options );

=cut

our $err_id;
our $err_msg;

sub decode_rjson {
    my ( $raw, %options ) = @_;
    use JSON::Relaxed::Parser;
    my $parser = JSON::Relaxed::Parser->new(%options);
    my $res = $parser->decode($raw);
    # Legacy.
    $err_id  = $parser->err_id;
    $err_msg = $parser->err_msg;

    return $res;
}

# Legacy.
sub from_rjson {
    my ( $raw, %options ) = @_;
    $options{croak_on_error} //= 0;
    decode_rjson( $raw, %options );
}

=head1 OBJECT-ORIENTED PARSING


=head2 new

Create a C<JSON::Relaxed> object, suitable for one or many operations.

    $parser = JSON::Relaxed->new( %options );

Options:

=over 4

=item strict

When set to a true value, enforces full compliance with the
L<RelaxedJSON.org|https://www.relaxedjson.org/specification> specification.

Default value is false, enabling JSON::Relaxed extensions.

=item croak_on_error

Disabled by default in legacy mode, enabled otherwise.

Causes parsing error to be signalled with an exception.

See L</"ERROR HANDLING">.

=item extra_tokens_ok

=item combined_keys

=item implied_outer_hash

=item prp

Enables/disables some of the extensions described
L<above|/REALLY RELAXED EXTENSIONS">.

=item key_order

Adds a key C<" key order "> to each hash, containing an array with the
hash keys in order of appearance. This is used for pretty printing.

=back

=head2 decode

This method parses the JSON string, passed as argument.

    $structure = $parser->decode($rjson);

=head2 parse

This is the same as decode, but also enables legacy mode.

=head2 err_id

=head2 err_pos

=head2 err_msg

Fetches the error information for the last error, if any.

Error ids are simple short strings, like C<"multiple-structures">.

C<err_pos> fetches the text position in the JSON string where the
error occured. Returns -1 if this information is not available.

C<err_msg> Fetches the text of the last error message.

For a full list, see L<JSON::Relaxed::ErrorCodes>.

=head2 strict

=head2 croak_on_error

=head2 extra_tokens_ok

=head2 combined_keys

=head2 implied_outer_hash

=head2 prp

=head2 pretty (see "encode")

=head2 key_order

=head2 booleans (see L<"Boolean values">)

Sets/resets options.

Note that the value must be assigned to, e.g.

    $parser->strict = 1;	# enable

=head2 encode

    $string = $parser->encode( data => $data, %options )

Produces a string with a really relaxed rendition of the data.
With option C<pretty>, the rendition is pretty-printed.

With option C<key_order> the order of hash keys will be taken from a
pseudo-key C<" key order ">. This pseudo-key is added when option
C<key_order> is passed to C<decode>.

A Perl structure is passed as C<data> option. This structure is encoded.
Note however that this structure may contain only strings, arrays and hashes.

Option C<schema> can be used to provide schema data for structure to
be encoded. For each item to be encoded, the schema is consulted and
the following schema items are prepended as comments: C<title>,
C<description>, and C<infoText>.

=cut

sub new {
    my ($class, %opts) = @_;
    return JSON::Relaxed::Parser->new(%opts);
}

use parent qw(Exporter);
BEGIN {
    our @EXPORT      = qw(decode_rjson);
    our @EXPORT_OK   = ( @EXPORT, qw(from_rjson) );
    our %EXPORT_TAGS = ( all => [ @EXPORT_OK ] );
}

=head1 MAPPING

=head2 RRJSON to Perl

=over 4

=item *

Numbers are unquoted strings. They will be mapped to numbers if the
repesentation is identical to the source.
For example, the unquoted string C<1> and the quoted string C<"1">
will both yield the number C<1>
The unquoted string C<1.0> will also yield the number C<1>,
but C<"1.0"> will yield the string C<"1.0">.

=item *

Unquoted C<null> will become C<undef>.

=item *

Unquoted C<true> and C<false> will yield JSON::Boolean objects that
test as boolean (true resp. false) and stringify as C<"true"> resp.
C<"false">. See L</"Boolean values"> how to change this behaviour.

Likewise unquoted C<on> and C<off> when option C<prp> is specified.

=item *

Other unquoted strings will be treated as quoted strings.

=back

=head2 Perl to RRJSON

=over 4

=item *

Numbers will be output as numbers.

=item *

Strings will be output as unquoted strings if possible, quoted strings
otherwise. Non-latin characters will be output as C<\u> escapes.
When some of the quotes C<" ' `> are embedded the others will be tried
for the string, e.g. C<"a\"b"> will yield C<'a"b'>.

All quotes are equal, there is no difference in interpretation.

=item *

Boolean objects will be output as unquoted C<true> and C<false>.

=item *

Undefined values will be output as C<null>.

=back

=head2 Boolean values

By default JSON::Boolean objects will be used for unquoted C<true> and
C<false>. The C<booleans> method can be used to change this.

    $parser->booleans = [ false-value, true-value ]

This sets the values to be used for C<true> and C<false>.
Default is

    $parser->booleans = [ $JSON::Boolean::false, $JSON::Boolean::true  ]

A non-array true value establishes the default.

Setting to a false value is the same as

    $parser->booleans = [ 0, 1 ]

With option C<prp>, unquoted C<on> is the same as C<true>, and C<off>
is the same as C<false>.

=head1 ERROR HANDLING

If the document cannot be parsed, JSON::Relaxed will throw an
exception.

In legacy mode, JSON::Relaxed returns an undefined
value and sets error indicators in $JSON::Relaxed::err_id and
$JSON::Relaxed::err_msg.

If parser property C<croak_on_error> is set to a false
value, it will behave as if in legacy mode.

For a full list of error codes, see L<JSON::Relaxed::ErrorCodes>.

=head1 AUTHOR

Johan Vromans F<jv@cpan.org>

Based on original code from Miko O'Sullivan F<miko@idocs.com>.

=head1 SUPPORT

Development of this module takes place on GitHub:
L<https://github.com/sciurius/perl-JSON-Relaxed>.

You can find documentation for this module with the perldoc command.

  perldoc JSON::Relaxed

Please report any bugs or feature requests using the issue tracker on
GitHub.

=head1 LICENSE

Copyright (c) 2024 by Johan Vromans. All rights reserved. This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. This software comes with B<NO
WARRANTY> of any kind.

=cut

1;
