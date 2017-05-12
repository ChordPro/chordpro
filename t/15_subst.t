#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Test::More;
my $tests = 0;

use_ok( qw(App::Music::ChordPro::Output::Common) );
$tests++;

our $config;

$config = { metadata => { separator => ":",
			},
	  };

my $s = { page => 24,
	  meta => { title => "Hi There!",
		    h => ["Z"],
		    head => ["yes"],
		  },
	};

while ( <DATA> ) {
    chomp;
    next unless $_;
    next if /^#/;
    my ( $tpl, $exp ) = split( /\t+/, $_ );
    my $res = App::Music::ChordPro::Output::Common::fmt_subst( $s, $tpl, 0 );
    is( $res, $exp, "$tpl -> $exp" );
    $tests++;
}

done_testing($tests);

__END__
abcd			abcd
ab%%cd			ab%cd
ab}cd			ab}cd
ab%pead			ab24ead
ab%{head}def		abyesdef
ab%{head}def%{head}xy	abyesdefyesxy
%{head}def		yesdef
X%{}Y			XY
X%{head}Y		XyesY
X%{head|foo}Y		XfooY
X%{head|This is %{}!}Y	XThis is yes!Y
X%{hexd|foo}Y		XY
X%{hexd|foo|bar}Y	XbarY
X%{head|x%{foo}y|bar}Y	XxyY
X%{hexd|x%{foo}y|bar}Y	XbarY
X%{head|x%{foo|ab|f%{}g}y}Y	XxfgyY
