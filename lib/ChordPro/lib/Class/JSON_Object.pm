#! perl

use v5.26;
use Object::Pad qw( :experimental(mop) :experimental(custom_field_attr) );
use utf8;

=head1 NAME

Class::JSON_Object - Role for Class::JSON_Object

=head1 SYNOPSIS

    use Object::Pad;

    class Action :does(Class::JSON_Object) {
      field $operation;
      field $arg;
    }

    # Create instance and load from JSON.
    my $op = Action->new->load('{"operation":"move","arg":42}');

    # Accessors are automatically provided.
    say "Operation = ", $op->operation;
    say "Arg = ", $op->arg;

=head1 DESCRIPTION

Many web services and apps exchange information in the form of
JavaScript objects in JSON format. This class, actually a role, makes
it easy to define classes that construct Perl objects that correspond to
the JSON objects.

The intention is that these Perl objects can easily be loaded from,
and serialized as JSON. However, they are useful for data classs too,
even without the JSON.

For example:

    class MyClass :does(Class::JSON_Object);

        # Fields, must be passed as params upon creation:

        field $myfield1   :param

        # All fields automatically get an accessor (even arrays and hashes).

        # Fields, filled in later:

        field $myfield2    :mutator;

        # Fields with preset values, add mutator if required:

        field $myfield2    = "some value";

        # Fields that hold objects:

        field $myfield3  :Class(SomeOtherDataClass);

        # Fields that are optional, with defaul value.

        field $myfield4  :Optional = "42";

=head1 CONSTRUCTOR

Class::JSON_Object is a role, and not constructed.

=cut

# Non-instanciable base class.
role Class::JSON_Object;

use Object::Pad::MetaFunctions qw( deconstruct_object ref_field );

our $VERSION = "0.01";
use Carp;

field $_json;			# JSON en/decoder

# An enumeration of the instance fields that are DataClass objects.
field %_descr;

BEGIN {
    # Register two custom attributes.
    Object::Pad::MOP::FieldAttr->register
	( Optional => permit_hintkey => "JSON_Object/Extra",);
    Object::Pad::MOP::FieldAttr->register
	( Class => permit_hintkey => "JSON_Object/Extra",);
};

ADJUST {
    $self->_descr;
};

sub import {
    $^H{"JSON_Object/Extra"}++;
}

################ Loading/Unloading ################

# Helper: Add not described fields (assumed scalar or scalar arrays)
# to the desciption.

method _descr() {
    return %_descr if exists $_descr{" done"};

    my $classmeta = Object::Pad::MOP::Class->for_class(__CLASS__);
    my ( $classname, @repr ) = deconstruct_object($self);

    while ( @repr ) {

	my $fieldname = shift(@repr);
	my $value = shift(@repr);
	my ( $class, $sigil, $name ) = $fieldname =~ m/^(.*)\.([\@\$\%])(.*)/;
	next unless $class eq __CLASS__;
	next if $name =~ /^_/;

	my $fieldmeta = $classmeta->get_field( $sigil . $name );

	my $ref = ref_field( $fieldname, $self );
	$_descr{$name}->{ref} //= $ref;
	$_descr{$name}->{optional} = 1
	  if $fieldmeta->has_attribute("Optional");
	$_descr{$name}->{class} = $fieldmeta->get_attribute_value("Class")
	  if $fieldmeta->has_attribute("Class");

	# Provide accessors.
	unless ( __CLASS__->can($name) ) {
	    no strict 'refs';
	    if ( $sigil eq '$' ) {
		# It is common to treat objects as scalar values.
		*{__CLASS__."::$name"} =
		  sub { ${ ref_field( $fieldname, $_[0] ) } }
	    }
	    elsif ( $sigil eq '@' ) {
		*{__CLASS__."::$name"} =
		  sub { wantarray
			? @{ref_field( $fieldname, $_[0] )}
			: ref_field( $fieldname, $_[0] ) }
	    }
	    elsif ( $sigil eq '%' ) {
		*{__CLASS__."::$name"} =
		  sub { wantarray
			? %{ref_field( $fieldname, $_[0] )}
			: ref_field( $fieldname, $_[0] ) }
	    }
	    else {
		croak("Unhandled field type: '$sigil'");
	    }
	}
    }

    $_descr{" done"} = 1;
    return %_descr;
}

=head2 load( $data )

Loads the object from the given data.

The data may be a hash or a JSON string.

=cut

method load( $data ) {
    my %descr = $self->_descr;
    $data = $self->json2perl($data) unless ref($data) eq 'HASH';
    croak("Data for ", __CLASS__, " must be HASH" ) unless ref($data) eq 'HASH';

    # Register the data keys.
    my %k = map { $_ => 1 } keys( %$data );

    # Process the description list.
    for my $key ( sort keys %descr ) {
	next if $key eq " done";
	next if $key =~ /^_/;

	if ( exists($data->{$key}) ) {

	    # We got a value for this key.
	    my $val = $data->{$key};
	    delete $k{$key};
	    my $v = $descr{$key};

	    my $class = $v->{class};
	    warn( __CLASS__ . ": key = \"$key\"",
		  $class ? ", class = $class" : "",
		  ", ref(\$v) = ", ref($v->{ref}),
		  ", ref(\$data->{$key}) = ",
		     ref($val), "\n" ) if 0;

	    if ( $class ) {	# Object
		# Check for array of objects.
		if ( ref($v->{ref}) eq 'ARRAY' && ref($val) eq 'ARRAY' ) {
		    @{$v->{ref}} = map { $class->new->load($_) } @$val;
		}
		else {
		    # Single object.
		    ${$v->{ref}} = $class->new->load($val);
		}
	    }

	    # Array of scalars.
	    elsif ( ref($v->{ref}) eq 'ARRAY' && ref($val) eq 'ARRAY' ) {
		@{$v->{ref}} = @$val;
	    }

	    # Hash.
	    elsif ( ref($v->{ref}) eq 'HASH' && ref($val) eq 'HASH' ) {
		%{$v->{ref}} = %$val;
	    }

	    # Single scalar.
	    else {
		${$v->{ref}} = $val;
	    }
	}
	else {
	    # There is no value for this field.
	    carp( __CLASS__ . ": Key \"$key\" missing in data")
	      unless $descr{$key}->{optional};
	}
    }

    if ( %k ) {
	# Got values that we do not have fields for.
	carp( __CLASS__ . ": Excess keys: \"",
	      join( "\", \"", sort keys %k ), "\"" );
    }

    $self;
}

=head2 hash()

Produce a plain hash from the object.

=cut

method hash {

    my $res = {};
    my %descr = $self->_descr;

    while ( my($k,$v) = each(%descr) ) {
	next if $k eq " done";
	next if $k =~ /^_/;

	my $key = $k;
	my $class = $v->{class};

	if ( $class ) {
	    if ( ref($v->{ref}) eq 'ARRAY' ) {
		# [ object, ... ]
		@{$res->{$key}} = map { $_->hash } @{$v->{ref}};
	    }
	    else {
		# single object
		$res->{$key} = ${$v->{ref}}->hash;
	    }
	}
	elsif ( ref($v->{ref}) eq 'ARRAY' ) {
	    # [ value, ... ]
	    @{$res->{$key}} = @{$v->{ref}};
	}
	elsif ( ref($v->{ref}) eq 'HASH' ) {
	    # { key => value, ... }
	    %{$res->{$key}} = %{$v->{ref}};
	}
	else {
	    # single value
	    $res->{$key} = ${$v->{ref}};
	}
    }

    $res;
}

=head2 json()

Produce a JSON string from the object.

=cut

method json {
    $self->perl2json( $self->hash );
}

################ Serialization ################

=head1 METHODS

=head2 json2perl( $json )

Serialization helper.
Decodes the JSON string and returns it as a Perl hash.

=cut

method json2perl( $json ) {
    require JSON::PP; $_json //= JSON::PP->new->canonical($ENV{TEST_ACTIVE}//0);
    $_json->decode($json);
}

=head2 json2perl( $json )

Serialization helper.
Encodes a Perl hash as a JSON string and returns it as .

=cut

method perl2json( $perl) {
    require JSON::PP; $_json //= JSON::PP->new->canonical($ENV{TEST_ACTIVE}//0);
    $_json->encode($perl);
}

=head1 AUTHOR

Johan Vromans, C<< <JV at cpan.org> >>

=head1 SUPPORT AND DOCUMENTATION

Development of this module takes place on GitHub:
https://github.com/sciurius/perl-Class-JSON_Object.

You can find documentation for this module with the perldoc command.

    perldoc Class::JSON_Object

Please report any bugs or feature requests using the issue tracker on
GitHub.

=head1 SEE ALSO

L<Object::Pad>.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2024 Johan Vromans, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Class::JSON_Object
