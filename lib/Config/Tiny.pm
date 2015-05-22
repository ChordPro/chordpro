package Config::Tiny;
 
# If you thought Config::Simple was small...

# This is even smaller. I removed the write part :)
 
use strict;
 
# Warning: There is another version line, in t/02.main.t.
 
our $VERSION = '2.22';
 
BEGIN {
        require 5.008001;
        $Config::Tiny::errstr  = '';
}
 
# Create an empty object
sub new { bless {}, shift }
 
# Create an object from a file
sub read {
        my $class = ref $_[0] ? ref shift : shift;
        my $file  = shift or return $class->_error('No file name provided');
 
        # Slurp in the file.
 
        my $encoding = shift;
        $encoding    = $encoding ? "<:$encoding" : '<';
        local $/     = undef;
 
        open( CFG, $encoding, $file ) or return $class->_error( "Failed to open file '$file' for reading: $!" );
        my $contents = <CFG>;
        close( CFG );
 
        return $class -> _error("Reading from '$file' returned undef") if (! defined $contents);
 
        return $class->read_string( $contents );
}
 
# Create an object from a string
sub read_string {
        my $class = ref $_[0] ? ref shift : shift;
        my $self  = bless {}, $class;
        return undef unless defined $_[0];
 
        # Parse the file
        my $ns      = '_';
        my $counter = 0;
        foreach ( split /(?:\015{1,2}\012|\015|\012)/, shift ) {
                $counter++;
 
                # Skip comments and empty lines
                next if /^\s*(?:\#|\;|$)/;
 
                # Remove inline comments
                s/\s\;\s.+$//g;
 
                # Handle section headers
                if ( /^\s*\[\s*(.+?)\s*\]\s*$/ ) {
                        # Create the sub-hash if it doesn't exist.
                        # Without this sections without keys will not
                        # appear at all in the completed struct.
                        $self->{$ns = $1} ||= {};
                        next;
                }
 
                # Handle properties
                if ( /^\s*([^=]+?)\s*=\s*(.*?)\s*$/ ) {
                        $self->{$ns}->{$1} = $2;
                        next;
                }
 
                return $self->_error( "Syntax error at line $counter: '$_'" );
        }
 
        $self;
}
 
# Error handling
sub errstr { $Config::Tiny::errstr }
sub _error { $Config::Tiny::errstr = $_[1]; undef }
 
1;
 
__END__
