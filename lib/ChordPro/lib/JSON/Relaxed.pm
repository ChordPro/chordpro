#! perl

use v5.26;
use utf8;

package JSON::Relaxed;

use JSON::Relaxed::Parser; our $VERSION = $JSON::Relaxed::Parser::VERSION;

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

It does, however, have some additional extensions to make it even more
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

=head1 EXTENSIONS

Extensions are enabled unless the option C<strict> is set.

=over 4

=item Leading commas in lists are allowed

For example,

    [ , 1 ]

=item Hash keys without values

JSON::Relaxed supports object keys without a specified value.
In that case the hash element is simply assigned the undefined value.

In the following example, a is assigned 1, and b is assigned undef:

    { a:1, b }

=item String continuation

Long strings can be split over multiple lines by putting a backslash
at the end of the line:

    "this is a " \
    "long string"

Note that this is different from

    "this is a \
    long string"

which B<embeds> the newline into the string.

=item Extended Unicode escapes

Unicode escapes in strings may contain an arbitrary number of hexadecimal
digits enclosed in braces:

    \u{1d10e}

This eliminates the need to use L<surrogates|https://unicode.org/faq/utf_bom.html#utf16-2> to obtain the same character:

    \uD834\uDD0E

=back

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
    decode_json( $raw, %options );
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

=item extra_tokens_ok

When set to a true value, allows (and ignores) trailing information
after the first complete JSON structure.

Disabled by default.

=item croak_on_error

Disabled by default in legacy mode, enabled otherwise.

Causes parsing error to be signalled with an exception.

See L</"ERROR HANDLING">.

=back

=head2 decode

This method parses the JSON string, passed as argument.

    $structure = $parser->decode($rjson);

=head2 parse

This is the same as decode, but also enables legacy mode.

=head2 err_id

Fetches the error id of the last error, if any.

Error ids are simple short strings, like C<"multiple-structures">.

For a full list, see L<JSON::Relaxed::ErrorCodes>.

=head2 err_pos

Fetches the text position in the JSON string where the error occured.
Returns -1 if this information is not available.

=head2 err_msg

Fetches the text of the last error message, if any.

For a full list, see L<JSON::Relaxed::ErrorCodes>.

=head2 croak_on_error

Enables/disables exceptions on parse errors.

Note that the value must be assigned to:

    $parser->croak_on_error = 1;	# enable

=head2 extra_tokens_ok

Note that the value must be assigned to:

    $parser->extra_tokens_ok = 0;	# disable

=head2 strict

Enables/disables strict conformance to the official specification,

Note that the value must be assigned to:

    $parser->strict = 1;	# enable

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

=head1 ERROR HANDLING

If the document cannot be parsed, JSON::Relaxed will throw an
exception.

In legacy mode, JSON::Relaxed returns an undefined
value and sets error indicators in $JSON::Relaxed::err_id and
$JSON::Relaxed::err_msg.

If parser property C<croak_on_error> is set to a false
value, it will always behave as if in legacy mode.

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
