package Pcode::Path::Group::List;

use Moose;
use Pcode::Path::Group;
with 'Pcode::Role::List';

has '_current_path_group' => (
    is => 'rw',
    isa => 'Pcode::Path::Group',
    documentation => 'Working path group',
);

sub current_path_group {
    my ( $self ) = @_;
    if ( $self->count == 0 ) {
        my $path_group = $self->new_path_group;
        $self->append( $path_group );
        $self->_current_path_group( $path_group );
    }
    if ( !$self->_current_path_group ) {
        $self->_current_path_group( $self->last );
    }
    return $self->_current_path_group;
}

sub paths_to_render {
    my ( $self ) = @_;
    if ( $self->_current_path_group ) {
        return $self->_current_path_group->paths_to_render;
    }
    return;
}

sub set_current_path_group {
    my ( $self, $path_group ) = @_;
    $self->_current_path_group( $path_group );
}

sub current_path {
    my ( $self ) = @_;
    return $self->current_path_group->current_path;
}

sub set_current_path {
    my ( $self, $path, $path_group ) = @_;
    $self->_current_path_group( $path_group );
    $self->_current_path_group->set_current_path( $path );
}

sub delete_last_command {
    my ( $self ) = @_;
    if ( $self->_current_path_group ) {
        $self->_current_path_group->delete_last_command;
    }
}

sub new_path {
    my ( $self ) = @_;
    return $self->current_path_group->new_path;
}

sub new_path_group {
    my ( $self, $name ) = @_;
    return Pcode::Path::Group->new( { name => $name || "New path group" } );
}

sub add_path_group {
    my ( $self, $path_group ) = @_;
    $self->append( $path_group );
    $self->_current_path_group( $path_group );
}

sub first_path {
    my ( $self ) = @_;
    return $self->current_path_group->first;
}

sub clear_all {
    my ( $self ) = @_;
    $self->foreach( sub {
        my ( $path_group ) = @_;
        $path_group->clear_all;
    } );
    $self->clear;
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

    # TODO: Needs more thought in general, as should not be
    # doing Gcode comments in here...

    $self->foreach( sub {
        my ( $path_group ) = @_;
        my @gcode_objects = $path_group->generate_gcode( $machine_center, $path_group->name );
        for my $gcode_obj ( @gcode_objects ) {
            return if !$gcode_obj;
            $full_gcode .= $gcode_obj->generate;
            $full_gcode .= "\n";
            $test_gcode .= $gcode_obj->generate_test;
            $test_gcode .= "\n";
        }
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
        my ( $path_group ) = @_;
        my ( $pmin, $pmax ) = $path_group->bounding_points;
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
