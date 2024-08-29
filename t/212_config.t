#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Config;

plan tests => 3;

my $config =
  { pdf =>
    { fonts =>
      { ape =>
	{ name => "Times-Roman",
	  file => "tim.ttf",
	  description => "serif",
	  size => 12
	},
	nut => "sans 12",
	mice =>
	{ name => "Times-Roman",
	  description => "serif",
	  size => 12
	},
	wime =>
	{ name => "Times-Roman",
	  description => "serif 14",
	  size => 12
	},
	yet =>
	{ name => "Times-Roman",
	  size => 12
	},
      }}};

ChordPro::Config::config_simplify_fonts($config);

is_deeply( $config,
	   { pdf =>
	     { fonts =>
	       { ape  => { file => 'tim.ttf', size => 12 },
		 nut  => 'sans 12',
		 mice => 'serif 12',
		 wime => 'serif 14',
		 yet  => 'Times-Roman 12',
	       }}},
	   "simplify fonts" );

ChordPro::Config::config_expand_font_shortcuts($config);

is_deeply( $config,
	   { pdf =>
	     { fonts =>
	       { ape  => { file => 'tim.ttf', size => 12 },
		 nut  => { description => 'sans 12' },
		 mice => { description => 'serif 12' },
		 wime => { description => 'serif 14' },
		 yet  => { name => 'Times-Roman', size => 12 },
	       }}},
	   "expand fonts 1" );

$config->{pdf}->{fonts}->{ape} = "tim.ttf 12";

ChordPro::Config::config_expand_font_shortcuts($config);

is_deeply( $config,
	   { pdf =>
	     { fonts =>
	       { ape  => { file => 'tim.ttf', size => 12 },
		 nut  => { description => 'sans 12' },
		 mice => { description => 'serif 12' },
		 wime => { description => 'serif 14' },
		 yet  => { name => 'Times-Roman', size => 12 },
	       }}},
	   "expand fonts 2" );

