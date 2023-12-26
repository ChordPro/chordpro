#! perl

use v5.26;
use feature qw( signatures );
no warnings qw( experimental::signatures );
use utf8;

package ChordPro::Dumper;

use Exporter qw(import);
our @EXPORT = qw(ddp);

use Data::Printer
  hash_separator  => " => ",
  escape_chars	  => "nonascii",
  print_escapes	  => 1,
  scalar_quotes	  => "'",
  caller_message_newline => 0,
  string_max      => 120,
  class => { parents    => 0,
	     linear_isa => 0,
	     show_methods    => "none",
	     show_overloads  => 0,
	     internals	     => 1 };

my $filters = [
  # Handle binary strings elegantly.
  { SCALAR => sub( $ref, $ddp ) {
	if ( $$ref =~ /[\000-\010\016-\037]/ ) {
	    my $s = $$ref;
	    if ( length($s) > 10 ) {
		$s = substr( $s, 0, 10 );
		$s = "'$s...' (" .length($s)." bytes)";
	    }
	    else {
		$s = qq{'$s'};
	    }
	    $s =~ s/([^[:print:]])/sprintf("\\x{%02x}", ord($1))/ge;
	    return $s;
	}
	return;
    } },

    # Try to compact hashes.
    { HASH => sub( $ref, $ddp ) {
	  my $str = Data::Printer::Filter::HASH::parse($ref, $ddp);
	  ( my $s = $str ) =~ s/\s+/ /g;
	  my $nl = $ddp->newline;
	  return length($s)+length($nl) < 80 ? $s : $str;
      } },

    # Try to compact arrays.
    { ARRAY => sub( $ref, $ddp ) {
	  my $str = do {
	      Data::Printer::Filter::ARRAY::parse($ref, $ddp);
	  };
	  my $s = $str;
	  $s =~ s/\n\s+\[\d+\]\s+/ /g;
	  $s =~ s/\s+/ /g;
	  my $nl = $ddp->newline;
	  return length($s)+length($nl) < 80 ? $s : $str;
      } },

    { 'PDF::API2::Resource::XObject::Form::Hybrid' => sub ( $ref, $ddp ) {
	  my @bb = $ref->bbox;
	  return ref($ref) . " [@bb]";
      } },

    { 'PDF::API2::Resource::XObject::Image' => sub ( $ref, $ddp ) {
	  return join( "", ref($ref),
		       " [", $ref->width, "x", $ref->height, "]",
		     );
      } },
];

sub ddp( $ref, %options ) {
    my %o = ( filters => $filters, %options );
    if ( $o{as} =~ /^(.*)\n\Z/s ) {
	$o{as} = $1;
	$o{caller_message_newline} = 1;
    }
    defined(wantarray)
      ? np( $ref, %o )
      : ( -t STDERR )
        ? p( $ref, %o )
        : warn( np( $ref, %o ), "\n" );
}

1;
