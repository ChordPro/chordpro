#!/usr/bin/perl

use strict;
use warnings;
use DBI;
use lib '../lib';
use App::Music::ChordPro;

my @v = split( /\./, "$App::Music::ChordPro::VERSION" );
die("No version info found?\n") unless @v;
push( @v, 0, 0, 0 );

my $dbh = DBI->connect("dbi:SQLite:dbname=cava20.cpkgproj");

my $sth = $dbh->prepare( "UPDATE config_values SET config_value = ?".
			 " WHERE config_name = ?" );

$sth->execute( shift(@v), 'version_major'   );
$sth->execute( shift(@v), 'version_minor'   );
$sth->execute( shift(@v), 'version_release' );
