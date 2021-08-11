#! perl

use strict;
use warnings;
use utf8;
use Carp;

package App::Music::ChordPro::Testing;

use base 'Exporter';
our @EXPORT = qw( $config );

use Test::More ();

use App::Packager ( ':name', 'App::Music::ChordPro' );
use App::Music::ChordPro::Config;

sub import {
    my $pkg = shift;

    # This is dirty...
    -d "t" && chdir "t";

    $::running_under_test = 1;
    App::Packager->export_to_level(1);
    Test::More->export_to_level(1);
    $pkg->export_to_level( 1, undef, @EXPORT );
}

sub is_deeply {
    my ( $got, $expect, $tag ) = @_;

    if ( ref($got) eq 'HASH' && ref($expect) eq 'HASH' ) {
	for ( qw( config chordsinfo ) ) {
	    delete $got->{$_} unless exists $expect->{$_};
	}
	for ( qw( instrument user ) ) {
	    delete $got->{meta}->{$_} unless exists $expect->{meta}->{$_};
	}
    }

    Test::More::is_deeply( $got, $expect, $tag );
}

push( @EXPORT, 'is_deeply' );

sub testconfig {
    # May change later.
    App::Music::ChordPro::Config::configurator;
}

push( @EXPORT, 'testconfig' );

our $config = testconfig();

{
no warnings 'redefine';

sub getresource {
    App::Packager::U_GetResource(@_);
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
    my ($str1, $str2);
    local($/);
    open(my $fd1, "<:encoding(utf-8)", $file1) or die("$file1: $!\n");
    $str1 = <$fd1>;
    close($fd1);
    open(my $fd2, "<:encoding(utf-8)", $file2) or die("$file2: $!\n");
    $str2 = <$fd2>;
    close($fd2);
    $str1 =~ s/[\n\r]+/\n/;
    $str2 =~ s/[\n\r]+/\n/;
    return 0 if $str1 eq $str2;
    1;
}

push( @EXPORT, 'differ' );

1;
