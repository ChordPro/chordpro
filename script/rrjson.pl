#!/usr/bin/perl

# Author          : Johan Vromans
# Created On      : Sun Mar 10 18:02:02 2024
# Last Modified By: 
# Last Modified On: Thu Jul 11 14:13:31 2024
# Update Count    : 138
# Status          : Unknown, Use with caution!

################ Common stuff ################

use v5.26;
use feature 'signatures';
no warnings 'experimental::signatures';

# Package name.
my $my_package = 'JSON::Relaxed';
# Program name and version.
my ($my_name, $my_version) = qw( rrjson 0.02 );

################ Command line parameters ################

use Getopt::Long 2.13;

# Command line options.
my $mode = "rrjson";
my $execute;			# direct JSON from command line
my $schema;			# schema (optional)

# Parser options.
my $strict;
my $pretty = 1;
my $croak_on_error;
my $extra_tokens_ok;

# Extension properties.
my $order;
my $prp;
my $combined_keys;
my $implied_outer_hash;

my $verbose = 1;		# verbose processing

# Development options (not shown with -help).
my $pretoks = 0;
my $tokens = 0;
my $debug = 0;			# debugging
my $trace = 0;			# trace (show process)
my $test = 0;			# test mode.

# Process command line options.
app_options();

# Post-processing.

# Default is non-strict.
$strict //= 0;
if ( $strict ) {
    # No extensions.
    $order                = 0;
    $prp                  = 0;
    $combined_keys        = 0;
    $implied_outer_hash   = 0;
}
else {
    # Default is all extensions.
    $order              //= 1;
    $prp                //= 1;
    $combined_keys      //= 1;
    $implied_outer_hash //= 1;
}

$trace |= ($debug || $test);

################ Presets ################

# For conditional filling of hashes.
sub maybe ( $key, $value, @rest ) {
    if (defined $key and defined $value) {
	return ( $key, $value, @rest );
    }
    else {
	( defined($key) || @rest ) ? @rest : ();
    }
}

################ The Process ################

use FindBin;
use lib "$FindBin::Bin/../lib";
use JSON::Relaxed;
use File::LoadLines;
use Encode qw(decode_utf8);
binmode STDOUT => ':utf8';
binmode STDERR => ':utf8';

if ( $schema ) {
    my $parser = JSON::Relaxed::Parser->new( strict => 0 );
    my $data = loadlines( $schema, { split => 0 } );
    $data = $parser->decode($data);
    warn("Schema $schema loaded\n") if $verbose;
    $schema = $data;
}

my $parser = JSON::Relaxed::Parser->new
  ( booleans		  => 1,	# force default
    strict	          => $strict,
    prp		          => $prp,
    combined_keys	  => $combined_keys,
    implied_outer_hash    => $implied_outer_hash,
    prp		          => $prp,
    pretty	          => $pretty,
    key_order	          => $order && $mode !~ /^json/,
    maybe croak_on_error  => $croak_on_error,
    maybe extra_tokens_ok => $extra_tokens_ok,
    );

if ( $mode eq "dumper" ) {
    $parser->booleans = [0,1];
}

if ( $verbose > 1 ) {
    my @opts;
    for ( qw( strict pretty prp combined_keys implied_outer_hash croak_on_error extra_tokens_ok booleans ) ) {
	push( @opts, $_ ) if $parser->$_;
    }
    if ( @opts ) {
	warn( "Parser options: ", join(", ", @opts), ".\n");
    }

}

for my $file ( @ARGV ) {

    my $json;
    my $prp;
    if ( $execute ) {
	$json = decode_utf8($file);
    }
    else {
	$prp = $file =~ /\.prp$/i;
	my $opts = { split => $prp, fail => "soft" };
	$json = loadlines( $file, $opts );
	die( "$file: $opts->{error}\n") if $opts->{error};
	if ( $pretoks || $tokens ) {
	    warn( "$file: PRP data, ignoring tokens\n" );
	}
    }

    my $data;

    # For debugging/development.
    if ( ( $pretoks || $tokens ) && !$prp ) {
	$parser->croak_on_error = 0;
	$parser->data = $json;
	$parser->pretokenize;
	if ( $pretoks ) {
	    my $pretoks = $parser->pretoks;
	    dumper( $pretoks, as => "Pretoks" );
	}
	$parser->tokenize;
	if ( $tokens && !$parser->is_error ) {
	    my $tokens = $parser->tokens;
	    dumper( $tokens, as => "Tokens" );
	}
	$data = $parser->structure unless $parser->is_error;
    }

    elsif ( $prp ) {
	require ChordPro::Config::Properties;
	*Data::Properties::_data_internal = \&Data::Properties::__data_internal;
	my $cfg = new Data::Properties;
	$cfg->parse_lines( $json, $file );
	$data = $cfg->data;
#	use DDumper; DDumper($data);exit;
    }

    # Normal call.
    else {
	$data = $parser->decode($json);
    }

    if ( $parser->is_error ) {
	warn( $execute ? "$file: JSON error: " : "",
	      "[", $parser->err_id, "] ", $parser->err_msg, "\n" );
	next;
    }

    if ( $mode eq "dump" || $mode eq "dumper" ) {
	dumper($data);
    }

    elsif ( $mode eq "rrjson" ) {
	print $parser->encode( data => $data,
			       maybe schema => $schema );
	print "\n" unless $pretty;
    }
    elsif ( $mode eq "rjson" ) {
	print $parser->encode( data => $data, strict => 1,
			       maybe schema => $schema );
	print "\n" unless $pretty;
    }
    elsif ( $mode eq "json_xs" ) {
	require JSON::XS;
	print ( JSON::XS->new->canonical->utf8(0)->pretty($pretty)
		->boolean_values( $JSON::Boolean::false, $JSON::Boolean::true )
		->convert_blessed->encode($data) );
    }

    else {			# default JSON
	require JSON::PP;
	print ( JSON::PP->new->canonical->utf8(0)->pretty($pretty)
		->boolean_values( $JSON::Boolean::false, $JSON::Boolean::true )
		->convert_blessed->encode($data) );
    }
}

################ Subroutines ################

package Data::Properties {

sub __data_internal {
    my ( $self, $orig ) = @_;
    my $cur = $orig // '';
    $cur .= "." if $cur ne '';
    my $all = $cur;
    $all .= '@';
    if ( my $res = $self->{_props}->{lc($all)} ) {
	if ( _check_array($res) ) {
	    my $ret = [];
	    foreach my $prop ( @$res ) {
		$ret->[$prop] = $self->_data_internal($cur.$prop);
	    }
	    return $ret;
	}
	else {
	    my $ret = @$res > 1 ? { " key order " => $res } : {};
	    foreach my $prop ( @$res ) {
		$ret->{$prop} = $self->_data_internal($cur.$prop);
	    }
	    return $ret;
	}
    }
    else {
	my $val = $self->{_props}->{lc($orig)};
	$val = $self->expand($val) if defined $val;
	return $val;
    }
}

}	# Data::Properties

################ Subroutines ################

sub dumper($data, %opts) {
    if ( $mode eq "dump" || %opts ) {
	my %opts = ( %opts );
	require Data::Printer;
	if ( -t STDOUT ) {
	    Data::Printer::p( $data, %opts );
	}
	else {
	    print( Data::Printer::np( $data, %opts ) );
	}
    }

    elsif ( $mode eq "dumper" ) {
	require Data::Dumper;
	local $Data::Dumper::Sortkeys  = 1;
	local $Data::Dumper::Indent    = 1;
	local $Data::Dumper::Quotekeys = 0;
	local $Data::Dumper::Deparse   = 1;
	local $Data::Dumper::Purity    = 1;
	local $Data::Dumper::Terse     = 1;
	local $Data::Dumper::Trailingcomma = 1;
	local $Data::Dumper::Useperl = 1;
	local $Data::Dumper::Useqq     = 0; # I want unicode visible
	print( Data::Dumper->Dump( [$data] ) );
    }
}

################ Subroutines ################

sub app_options() {
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally

    # Process options, if any.
    if ( !GetOptions(
     'schema=s'		    => \$schema,
     'rrjson'		    => sub { $mode = "rrjson"  },
     'rjson'		    => sub { $mode = "rjson"   },
     'json|json_pp'	    => sub { $mode = "json"    },
     'json_xs'		    => sub { $mode = "json_xs" },
     'dump'		    => sub { $mode = "dump"    },
     'dumper'		    => sub { $mode = "dumper"  },
     'execute|e'	    => \$execute,
     'strict!'		    => \$strict,
     'prp!'		    => \$prp,
     'combined_keys!'	    => \$combined_keys,
     'implied_outer_hash!'  => \$implied_outer_hash,
     'croak_on_error!'	    => \$croak_on_error,
     'extra_tokens_ok!'	    => \$extra_tokens_ok,
     'pretty!'		    => \$pretty,
     'order!'		    => \$order,
     'pretoks+'		    => \$pretoks,
     'tokens+'		    => \$tokens,
     'ident'		    => \$ident,
     'verbose+'		    => \$verbose,
     'quiet'		    => sub { $verbose = 0 },
     'trace'		    => \$trace,
     'help|?'		    => \$help,
     'debug'		    => \$debug ) or $help) {
	app_usage(2);
    }
    app_ident() if $ident;
    app_usage(2) unless @ARGV;
}

sub app_ident() {
    print STDERR ("This is $my_package [$my_name $my_version]\n");
    print STDERR ("JSON::Relaxed version $JSON::Relaxed::VERSION\n");
}

sub app_usage( $exit ) {
    app_ident();
    print STDERR <<EndOfUsage;
Usage: $0 [options] [file ...]
  Inputs
   --execute -e		args are JSON, not filenames
   --schema=XXX		optional JSON schema
  Output modes
   --rrjson		pretty printed RRJSON output (default)
   --rjson		pretty printed RJSON output
   --json		JSON output (default)
   --json_xs		JSON_XS output
   --no-pretty		compact (non-pretty) output
   --order		retain order of hash keys
   --dump		dump structure (Data::Printer)
   --dumper		dump structure (Data::Dumper)
  Parser options
   --strict		see the docs
  Miscellaneous
   --ident		shows identification
   --help		shows a brief help message and exits
   --verbose		provides more verbose information
   --quiet		runs as silently as possible
EndOfUsage
    exit $exit if defined $exit && $exit != 0;
}
