#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Test::More tests => 12;
use App::Music::ChordPro::Config;

our $config = bless
  {
   outer => { foo => 1,
	      bar => [ qw(aap noot mies) ],
	      blech => 'q',
	    },
   inner => { foo => 2,
	      bar => [ qw(aap noot mies) ],
	      outer =>
	      { foo => 3,
		bar => [ qw(three blind mice) ],
		blech => 'a',
	      }
	    },
  } => 'App::Music::ChordPro::Config';

is( _c("outer.foo"), "1" );
is( _c("outer.bar.1"), "noot" );
is( _c("inner.foo"), "2" );
is( _c("inner.bar.1"), "noot" );
is( _c("inner.outer.foo"), "3" );
is( _c("inner.outer.bar.1"), "blind" );
$config->set_context("inner");
is( _c("foo"), "2" );
is( _c("bar.1"), "noot" );
is( _c("blech","x"), "x" );
$config->set_context("inner.outer");
is( _c("foo"), "3" );
is( _c("bar.1"), "blind" );
is( _c("blech","x"), "a" );

