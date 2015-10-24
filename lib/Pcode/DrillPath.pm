package Pcode::DrillPath;

use Moose;
use Pcode::PointList;
use Pcode::CommandList;

with 'Pcode::Role::Layer';

has 'commands' => (
    is  => 'rw',
    isa => 'Pcode::CommandList',
    default => sub { return Pcode::CommandList->new() },
    documentation => 'List of commands',
);

has name => (
    is  => 'rw',
    isa => 'Str',
    default => 'Drill points',
    documentation => 'The name of the path',
);

has depth => (
    is  => 'rw',
    isa => 'Num',
    required => 1,
    default => 4.8,
    documentation => 'The depth of the cut in mm',
);

has 'overcut' => (
    is  => 'rw',
    isa => 'Num',
    default => 0.2,
    documentation => 'How much to cut under the depth',
);

sub properties {
    my ( $self ) = @_;
    return [
        {
            name  => 'name',
            label => 'Name',
            type  => 'Str',
        },
        {
            name  => 'needs_render',
            label => 'Needs render',
            type  => 'Bool',
        },
        {
            name  => 'depth',
            label => 'Depth',
            type  => 'Num',
        },
        {
            name  => 'overcut',
            label => 'Overcut',
            type  => 'Num',
        },
    ];
}

sub clear {
    my ( $self ) = @_;
    $self->commands->clear;
    $self->needs_render( 1 );
}

sub select {
    my ( $self, $selected_command ) = @_;
    $self->commands->foreach( sub {
        my ( $command ) = @_;
        $command->hover( 0 );
    } );
    $selected_command->hover( 1 );
    $self->needs_render( 1 );
}

sub nr_commands {
    my ( $self ) = @_;
    return $self->commands->count;
}

sub delete_last {
    my ( $self ) = @_;
    $self->commands->pop;
    $self->regenerate_tool_paths;
    $self->needs_render( 1 );
}

sub stringify {
    my ( $self ) = @_;
    return $self->commands->stringify;
}

sub append_command {
    my ( $self, $command ) = @_;
    $self->commands->append( $command );
    $self->needs_render( 1 );
}

sub last_command {
    my ( $self ) = @_;
    return $self->commands->last;
}

sub bounding_points {
    my ( $self ) = @_;
    return $self->commands->bounding_points;
}

sub render_layer {
    my ( $self, $app, $cr ) = @_;
    $self->render_commands( $app, $cr );
}

sub render_commands {
    my ( $self, $app, $cr ) = @_;

    $self->commands->foreach( sub {
        my ( $command ) = @_;
        $command->render( $app, $cr );
    } );
}

sub serialize {
    my ( $self ) = @_;

    my $objects = [];

    $self->commands->foreach( sub {
        my ( $command ) = @_;
        push @{ $objects }, $command->serialize;
    } );

    return {
        name        => $self->name,
        depth       => $self->depth,
        overcut     => $self->overcut,
        commands    => $objects,
    };
}

sub translate {
    my ( $self, $x, $y ) = @_;
    $self->commands->foreach( sub {
        my ( $command ) = @_;
        $command->translate( $x, $y );
    } );
}

sub generate_gcode {
    my ( $self, $machine_center ) = @_;
    return $self->commands->generate_gcode( {
        offset  => {
            X => $machine_center->X,
            Y => $machine_center->Y,
        },
        depth   => $self->depth,
        overcut => $self->overcut,
    } );
}

1;
