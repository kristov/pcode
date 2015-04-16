package Pcode::PathList;

use Moose;
use Pcode::Path;
with 'Pcode::Role::List';

sub new_path {
    my ( $self ) = @_;
    my $path = Pcode::Path->new();
    $self->append( $path );
    return $path;
}

sub nr_paths {
    my ( $self ) = @_;
    return $self->count;
}

sub delete_last_path {
    my ( $self ) = @_;
    $self->pop;
    return $self->last;
}

sub translate {
    my ( $self, $x, $y ) = @_;
    $self->foreach( sub {
        my ( $path ) = @_;
        $path->translate( $x, $y );
    } );
}

sub generate_gcode {
    my ( $self, $machine_center ) = @_;

    my $full_gcode = "";
    my $test_gcode = "";

    $self->foreach( sub {
        my ( $path ) = @_;
        my $gcode_obj = $path->generate_gcode( $machine_center );
        $full_gcode .= $gcode_obj->generate;
        $full_gcode .= "\n";
        $test_gcode .= $gcode_obj->generate_test;
        $test_gcode .= "\n";
    } );

    return ( $full_gcode, $test_gcode );
}

1;
