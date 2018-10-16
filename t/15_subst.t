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
    my $res = App::Music::ChordPro::Output::Common::fmt_subst( $s, $tpl );
    is( $res, $exp, "$tpl -> $exp" );

    $tests++;
}

done_testing($tests);

__END__
# No substitutions
abcd			abcd

# Percent -> %
ab%%cd			ab%%cd

# Lone brace
ab}cd			ab}cd

# Short (single character) variable -- nope, we don't do this anymore.
ab%pead			ab%pead

# Meta variable
ab%{head}def		abyesdef
ab%{head}def%{head}xy	abyesdefyesxy
%{head}def		yesdef
%{h}def			Zdef
X%{}Y			XY

# Subtitute the value
X%{head}Y		XyesY

# Subtitute the 'true' part
X%{head|foo}Y		XfooY
X%{hexd|foo}Y		XY

# %{} refers to the value of the key.
X%{head|This is %{}!}Y	XThis is yes!Y
X%{head=yes|This is %{}!}Y	XThis is yes!Y
X%{head=no|This is %{}!}Y	XY

# Subtitute the 'false' part
X%{head=no|foo|bar}Y	XbarY
X%{hexd|foo|bar}Y	XbarY
X%{hexd=yes|foo|bar}Y	XbarY
X%{hexd=no|foo|bar}Y	XbarY
X%{hexd=|foo|bar}Y	XfooY
X%{h|foo|bar}Y		XfooY
X%{h=Z|foo|bar}Y	XfooY

# Nested.
X%{head|x%{foo}y|bar}Y	XxyY
X%{hexd|x%{foo}y|bar}Y	XbarY

# Note that %{} is the value of foo (inner), not head (outer)
X%{head|x%{foo|ab|f%{}g}y}Y	XxfgyY
