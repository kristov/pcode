package Pcode::Path::List;

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

sub delete_path {
    my ( $self, $path ) = @_;
    return $self->delete_this( $path );
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
        return if !$gcode_obj;
        $full_gcode .= $gcode_obj->generate;
        $full_gcode .= "\n";
        $test_gcode .= $gcode_obj->generate_test;
        $test_gcode .= "\n";
    } );

    return ( $full_gcode, $test_gcode );
}

sub bounding_points {
    my ( $self ) = @_;

    my $minx;
    my $miny;
    my $maxx;
    my $maxy;

    return if $self->count == 0;

    $self->foreach( sub {
        my ( $path ) = @_;
        my ( $pmin, $pmax ) = $path->bounding_points;
        return if !$pmax;
        $minx = $pmin->X if !defined $minx || $pmin->X < $minx;
        $miny = $pmin->Y if !defined $miny || $pmin->Y < $miny;
        $maxx = $pmax->X if !defined $maxx || $pmax->X > $maxx;
        $maxy = $pmax->Y if !defined $maxy || $pmax->Y > $maxy;
    } );

    return if ( !defined $minx || !defined $miny || !defined $maxx || !defined $maxy );

    return (
        Pcode::Point->new( { X => $minx, Y => $miny } ),
        Pcode::Point->new( { X => $maxx, Y => $maxy } ),
    );
}

1;
