#! perl

use strict;
use warnings;
use utf8;
binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');

foreach my $file ( @ARGV ) {
    open( my $fd, '<:utf8', $file ) || die("$file: $!\n");

    my $out = $file =~ s/\.wxg$/.txt/r;
    open( my $of, '>:utf8', $out ) || die("$out: $!\n");
    print $of ( "# $file\n\n" );
    my $level = 0;
    my @indent = ("");
    my $indent = "";
    my $prv = "";
    my %handlers;
    L: while ( <$fd> ) {
	next unless /^( +)\<object class="(.+?)" name="(.+?)" base="(.+?)"\>/;

	my ( $lvl, $class, $name, $base ) = ( length($1), $2, $3, $4 );
	if ( $lvl > $level ) {
	    $indent[$lvl] = $indent .= "  ";
	    $level = $lvl;
	    $prv =~ s/(^\s*)- /$1+ /;
	}
	elsif ( $lvl < $level ) {
	    $indent = $indent[$lvl];
	    $level = $lvl;
	}

	my @handlers;
	if ( scalar(<$fd>) =~ m;<events>; ) {
	    while ( scalar(<$fd>) =~ m;<handler.*?>(.*?)</handler>; ) {
		push( @handlers, $1 );
		if ( exists $handlers{$1} ) {
		    warn("ERROR: dup handler: $1\n");
		}
		else {
		    $handlers{$1}++;
		}
	    }
	}

	print $of ($prv) if $prv;
	my $h = "";
	$h = " -> " . join(",",@handlers) if @handlers;
	$prv = sprintf( "%s- %s (%s)%s\n",
			substr($indent,2), $name, $class, $h);

###	redo;
    }
    print $of ($prv) if $prv;

    print $of ( "\n",
		join( "\n", sort keys %handlers ), "\n");
    close($of);
}

