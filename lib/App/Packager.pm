#! perl

package App::Packager;

use strict;
use warnings;
use Carp;

# Implementation agnostic packager support.

our $VERSION   = "1.420";
our $PACKAGED  = 0 ;

sub import {

    # PAR::Packer.

    if ( $ENV{PAR_0} ) {
	require PAR;
	$VERSION          = $PAR::VERSION;
	$PACKAGED	  = 1;
	*IsPackaged       = sub { 1 };
	*GetScriptCommand = sub { $ENV{PAR_PROGNAME} };
	*GetAppRoot       = sub { $ENV{PAR_TEMP} };
	*GetResourcePath  = sub { $ENV{PAR_TEMP} . "/inc/res" };
	*GetResource      = sub { $ENV{PAR_TEMP} . "/inc/res/" . $_[0] };
	*Packager         = sub { "PAR Packer" };
	return;
    }

    if ( $Cava::Packager::PACKAGED ) {
	*Packager   = sub { "Cava Packager" };
	*IsPackaged = sub { 1 };
    }
    else {
	*Packager   = sub { return };
	*IsPackaged = sub { return };
    }

}

# Cava::Packager provides packaged and non-packaged functions.

our $AUTOLOAD;

sub AUTOLOAD {
    my $sub = $AUTOLOAD;
    $sub =~ s/^App\:\:Packager\:\://;

    eval { require Cava::Packager } unless $Cava::Packager::PACKAGED;
    my $can = Cava::Packager->can($sub);
    unless ( $can ) {
	require Carp;
	Carp::croak("Undefined subroutine \&$AUTOLOAD called");
    }

    no strict 'refs';
    *{'App::Packager::'.$sub} = $can;
    goto &$AUTOLOAD;
}
1;
