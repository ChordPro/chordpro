#! perl

use strict;
use warnings;
use utf8;

use App::Music::ChordPro::Testing;
use App::Music::ChordPro::Utils;

plan tests => 2;

is_deeply( parse_kv ( "foo bar foo xxx=yyy zzz='abc def'" ),
	   { foo => 2, bar => 1,
	     xxx => 'yyy', zzz => 'abc def' } );

is_deeply( parse_kv ( "no-foo no_bar noblech=1" ),
	   { foo => 0, bar => 0, noblech => 1 } );
