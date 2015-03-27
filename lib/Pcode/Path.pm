package Pcode::Path;

use Moose;
use Pcode::SnapList;
use Pcode::PointList;
use Pcode::CommandList;

has 'commands' => (
    is  => 'rw',
    isa => 'Pcode::CommandList',
    default => sub { return Pcode::CommandList->new() },
    documentation => 'List of commands',
);

has 'snaps' => (
    is  => 'rw',
    isa => 'Pcode::SnapList',
    default => sub { return Pcode::SnapList->new() },
    documentation => 'List of snap objects',
);

has 'points' => (
    is  => 'rw',
    isa => 'Pcode::PointList',
    default => sub { return Pcode::PointList->new() },
    documentation => 'List of snap intersection point objects',
);

sub detect_point_snap {
    my ( $self, $app, $x, $y ) = @_;
    return $self->commands->detect_point_snap( $app, $x, $y );
}

sub detect_line_snap {
    my ( $self, $app, $x, $y ) = @_;
    return $self->commands->detect_line_snap( $app, $x, $y );
}

sub clear {
    my ( $self ) = @_;
    $self->commands->clear;
    $self->snaps->clear;
    $self->points->clear;
}

sub stringify {
    my ( $self ) = @_;
    return $self->commands->stringify;
}

sub append_command {
    my ( $self, $command ) = @_;
    $self->commands->append( $command );
}

sub append_snap {
    my ( $self, $command ) = @_;
    $self->snaps->append( $command );
}

sub recalculate_points {
    my ( $self ) = @_;
    my @points = $self->snaps->recalculate_points;
    $self->points->clear;
    for my $point ( @points ) {
        $self->points->append( $point );
    }
}

sub render {
    my ( $self, $app, $cr ) = @_;
    $self->render_snaps( $app, $cr );
    $self->render_points( $app, $cr );
    $self->render_commands( $app, $cr );
}

sub render_snaps {
    my ( $self, $app, $cr ) = @_;

    $self->snaps->foreach( sub {
        my ( $command ) = @_;
        $command->render( $app, $cr );
    } );
}

sub render_points {
    my ( $self, $app, $cr ) = @_;

    $self->points->foreach( sub {
        my ( $command ) = @_;
        $command->render( $app, $cr );
    } );
}

sub render_commands {
    my ( $self, $app, $cr ) = @_;

    $self->commands->foreach( sub {
        my ( $command ) = @_;
        $command->render( $app, $cr );
    } );
}

1;
