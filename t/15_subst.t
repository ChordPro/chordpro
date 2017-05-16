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
    next if /^#/;
    next unless /\S/;
    chomp;

    my ( $tpl, $exp ) = split( /\t+/, $_ );
    my $res = App::Music::ChordPro::Output::Common::fmt_subst( $s, $tpl, 0 );
    is( $res, $exp, "$tpl -> $exp" );

    $tests++;
}

done_testing($tests);

__END__
# No substitutions
abcd			abcd

# Double percent -> %
ab%%cd			ab%cd

# Lone brace
ab}cd			ab}cd

# Short (single character) variable
ab%pead			ab24ead

# Meta variable
ab%{head}def		abyesdef
ab%{head}def%{head}xy	abyesdefyesxy
%{head}def		yesdef
X%{}Y			XY

# Subtitute the value
X%{head}Y		XyesY

# Subtitute the 'true' part
X%{head|foo}Y		XfooY
X%{hexd|foo}Y		XY

# %{} refers to the value of the key.
X%{head|This is %{}!}Y	XThis is yes!Y

# Subtitute the 'false' part
X%{hexd|foo|bar}Y	XbarY

# Nested.
X%{head|x%{foo}y|bar}Y	XxyY
X%{hexd|x%{foo}y|bar}Y	XbarY

# Note that %{} is the value of foo (inner), not head (outer)
X%{head|x%{foo|ab|f%{}g}y}Y	XxfgyY
