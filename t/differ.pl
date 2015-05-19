# $Id: differ.pl,v 1.1 2001-06-23 12:35:56+02 jv Exp $

sub differ {
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

1;
