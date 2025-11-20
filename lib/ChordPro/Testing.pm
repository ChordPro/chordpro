#! perl

use strict;
use warnings;
use utf8;
use Carp;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../lib/ChordPro/lib";

binmode STDOUT => ':utf8';
binmode STDERR => ':utf8';

package ChordPro::Testing;

use parent 'Exporter';
our @EXPORT = qw( $config );

use Test::More ();

use ChordPro::Files;
use ChordPro::Config;
use ChordPro::Paths;
use ChordPro::Chords;

sub import {
    my $pkg = shift;

    # This is dirty...
    -d "t" && chdir "t";

    $::running_under_test = 1;
    Test::More->export_to_level(1);
    $pkg->export_to_level( 1, undef, @EXPORT );
}

sub is_deeply {
    my ( $got, $expect, $tag ) = @_;

    if ( ref($got) eq 'HASH' && ref($expect) eq 'HASH' ) {
	fixchords($got) if $got->{body};

	for ( qw( config generate ) ) {
	    delete $got->{$_} unless exists $expect->{$_};
	}
	if ( $got->{chordsinfo} ) {
	    if ( !%{$got->{chordsinfo}} && !$expect->{chordsinfo} ) {
		delete $got->{chordsinfo};
	    }
	    else {
		foreach ( keys %{ $got->{chordsinfo} } ) {
		    $got->{chordsinfo}{$_} = $got->{chordsinfo}{$_}->name;
		}
	    }
	}
	for ( qw( instrument user key_from key_actual chords numchords
		  _configversion bookmark
	       ) ) {
	    delete $got->{meta}->{$_} unless exists $expect->{meta}->{$_};
	}
    }

    Test::More::is_deeply( $got, $expect, $tag );
}

push( @EXPORT, 'is_deeply' );

sub testconfig {
    # May change later.
    ChordPro::Config::configurator;
}

push( @EXPORT, 'testconfig' );

our $config = testconfig();

ChordPro::Chords::add_config_chord
  ( { name => "NC", base => 1, frets => [ (-1)x6 ], fingers => [] } );

{
no warnings 'redefine';

sub getresource {
    CP->findres($_[0]);
}
}

push( @EXPORT, 'getresource' );

sub cmp {
    # Perl version of the 'cmp' program.
    # Returns 1 if the files differ, 0 if the contents are equal.
    my ($old, $new) = @_;
    unless ( open (F1, $old) ) {
	print STDERR ("$old: $!\n");
	return 1;
    }
    unless ( open (F2, $new) ) {
	print STDERR ("$new: $!\n");
	return 1;
    }
    my ($buf1, $buf2);
    my ($len1, $len2);
    while ( 1 ) {
	$len1 = sysread (F1, $buf1, 10240);
	$len2 = sysread (F2, $buf2, 10240);
	return 0 if $len1 == $len2 && $len1 == 0;
	return 1 if $len1 != $len2 || ( $len1 && $buf1 ne $buf2 );
    }
}

sub differ {
    my ($file1, $file2) = @_;
    $file2 = "$file1" unless $file2;
    $file1 = "$file1";

    my @lines1 = @{ fs_load( $file1, { fail => 'hard' } ) };
    my @lines2 = @{ fs_load( $file2, { fail => 'hard' } ) };
    my $linesm = @lines1 > @lines2 ? @lines1 : @lines2;
    for ( my $line = 1; $line < $linesm; $line++ ) {
	next if $lines1[$line] eq $lines2[$line];
	Test::More::diag("Files $file1 and $file2 differ at line $line");
	Test::More::diag("  <  $lines1[$line]");
	Test::More::diag("  >  $lines2[$line]");
	return 1;
    }
    return 0 if @lines1 == @lines2;
    $linesm++;
    Test::More::diag("Files $file1 and $file2 differ at line $linesm" );
    Test::More::diag("  <  ", $lines1[$linesm] // "***missing***");
    Test::More::diag("  >  ", $lines2[$linesm] // "***missing***");
    1;
}

push( @EXPORT, 'differ' );

sub fixchords {
    my ( $s ) = @_;
    for ( @{ $s->{body} // [] } ) {
	for ( @{ $_->{chords} // [] } ) {
	    $_ = $_->key if UNIVERSAL::can( $_, "key" );
	}
	for ( @{ $_->{chorus} // [] } ) {
	    for ( @{ $_->{chords} // [] } ) {
		$_ = $_->key if UNIVERSAL::can( $_, "key" );
	    }
	}
	for ( @{ $_->{tokens} // [] } ) {
	    if ( $_->{class} eq "chord" ) {
		for ( $_->{chord} ) {
		    $_ = $_->key;
		}
	    }
	    elsif ( $_->{class} eq "chords" ) {
		for ( @{ $_->{chords} } ) {
		    $_ = $_->key;
		}
	    }
	}
    }
}

push( @EXPORT, 'fixchords' );

1;
