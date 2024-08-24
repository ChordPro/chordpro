#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Songbook;

plan tests => 3;

# Prevent a dummy {body} for chord grids.
$config->{diagrams}->{show} = 0;
my $s = ChordPro::Songbook->new;

# Image (minimal).
my $data = <<EOD;
{title Testing images}

{image id="yellow" x=100% scale="0.5" border="1" anchor="line"}
{image id="yellow" x=-30 scale="0.5" border="1" anchor="line"}
{c This line has two image hint}

{start_of_svg}
id=green
center=0
<svg width="50" height="50" viewBox="0 0 50 50">
<rect x="0" y="0" width="100%" height="100%" stroke="none" fill="lime"/>
</svg>
{end_of_svg}

{image id=green}
{c Green box above (centered)}

{start_of_svg}
center=0
<svg width="50" height="50" viewBox="0 0 50 50">
<rect x="0" y="0" width="100%" height="100%" stroke="none" fill="blue"/>
</svg>
{end_of_svg}
{c Blue box above (centered)}

##image: id=yellow persist=1
# /9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAMCAgICAgMCAgIDAwMDBAYEBAQEBAgGBgUGCQgKCgkI
# CQkKDA8MCgsOCwkJDRENDg8QEBEQCgwSExIQEw8QEBD/2wBDAQMDAwQDBAgEBAgQCwkLEBAQEBAQ
# EBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBD/wAARCAAyADIDAREA
# AhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAn/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFgEB
# AQEAAAAAAAAAAAAAAAAAAAYJ/8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAwDAQACEQMRAD8AoKyq
# XAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD//2Q==
##asset: id=red type=svg persist=1
# <svg width="50" height="50" viewBox="0 0 50 50">
# <rect x="0" y="0" width="100%" height="100%" stroke="none" fill="red"/>
# </svg>
EOD

eval { $s->parse_file(\$data) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'ChordPro::Song', "It's a song" );
#use DDP; p $s->{songs}->[0];
delete( $s->{songs}->[0]->{assets}->{yellow}->{data} )
  if $s->{songs}->[0]->{assets}->{yellow}->{data} =~ /^\xff\xd8\xff\xe0/;

my $song = {
	    'assets' => {
			 'yellow' => {
				      'height' => 50,
				      'width' => 50,
				      'type' => 'image',
				      'subtype' => 'jpg',
				      opts => { id => 'yellow',
						'persist' => 1 }
				     },
			 'red' => {
				   'data' => [
					      '<svg width="50" height="50" viewBox="0 0 50 50">',
					      '<rect x="0" y="0" width="100%" height="100%" stroke="none" fill="red"/>',
					      '</svg>'
					     ],
				   'handler' => 'svg2svg',
				   'type' => 'image',
				   'subtype' => 'svg',
				   opts => { id => 'red',
					     type => 'svg',
					     'persist' => 1 },
				   'module' => 'SVG'
				  },
			 'green' => {
				     'delegate' => 'SVG',
				     'data' => [
						'<svg width="50" height="50" viewBox="0 0 50 50">',
						'<rect x="0" y="0" width="100%" height="100%" stroke="none" fill="lime"/>',
						'</svg>'
					       ],
				     'opts' => {
						'id' => 'green',
						'center' => '0'
					       },
				     'type' => 'image',
				     'handler' => 'svg2svg',
				     'subtype' => 'delegate'
				    },
			 '_Image001' => {
					 'handler' => 'svg2svg',
					 'type' => 'image',
					 'subtype' => 'delegate',
					 'delegate' => 'SVG',
					 'data' => [
						    '<svg width="50" height="50" viewBox="0 0 50 50">',
						    '<rect x="0" y="0" width="100%" height="100%" stroke="none" fill="blue"/>',
						    '</svg>'
						   ],
					 'opts' => {
						    'center' => '0'
						   }
					}
			},
	    'meta' => {
		       'songindex' => 1,
		       'chords' => [],
		       'numchords' => [
				       0
				      ],
		       'title' => [
				   'Testing images'
				  ]
		      },
	    'settings' => {},
	    'title' => 'Testing images',
	    'chordsinfo' => {},
	    'source' => {
			 'file' => '__STRING__',
			 'line' => 1
			},
	    'body' => [
		       {
			'context' => '',
			'type' => 'empty'
		       },
		       {
			'context' => '',
			'opts' => {
				   'border' => '1',
				   'anchor' => 'line',
				   'scale' => [0.5,0.5],
				   'x' => '100%'
				  },
			'id' => 'yellow',
			'type' => 'image'
		       },
		       {
			'id' => 'yellow',
			'type' => 'image',
			'opts' => {
				   'border' => '1',
				   'scale' => [0.5,0.5],
				   'anchor' => 'line',
				   'x' => '-30'
				  },
			'context' => ''
		       },
		       {
			'orig' => 'This line has two image hint',
			'text' => 'This line has two image hint',
			'type' => 'comment',
			'context' => ''
		       },
		       {
			'type' => 'empty',
			'context' => ''
		       },
		       {
			'value' => '',
			'name' => 'context',
			'type' => 'set',
			'context' => 'svg'
		       },
		       {
			'context' => '',
			'type' => 'empty'
		       },
		       {
			'opts' => {},
			'id' => 'green',
			'type' => 'image',
			'context' => ''
		       },
		       {
			'text' => 'Green box above (centered)',
			'type' => 'comment',
			'context' => '',
			'orig' => 'Green box above (centered)'
		       },
		       {
			'type' => 'empty',
			'context' => ''
		       },
		       {
			'context' => 'svg',
			'type' => 'image',
			'id' => '_Image001',
			'opts' => {
				   'center' => '0'
				  }
		       },
		       {
			'context' => 'svg',
			'type' => 'set',
			'name' => 'context',
			'value' => ''
		       },
		       {
			'orig' => 'Blue box above (centered)',
			'context' => '',
			'type' => 'comment',
			'text' => 'Blue box above (centered)'
		       },
		       {
			'type' => 'empty',
			'context' => ''
		       }
		      ],
	    'structure' => 'linear',
	    'system' => 'common'
	   };

is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );
