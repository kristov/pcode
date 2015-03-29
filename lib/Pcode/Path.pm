package Pcode::Path;

use Moose;
use Pcode::PointList;
use Pcode::CommandList;

has 'commands' => (
    is  => 'rw',
    isa => 'Pcode::CommandList',
    default => sub { return Pcode::CommandList->new() },
    documentation => 'List of commands',
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
}

sub stringify {
    my ( $self ) = @_;
    return $self->commands->stringify;
}

sub append_command {
    my ( $self, $command ) = @_;
    $self->commands->append( $command );
}

sub render {
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

    return { commands => $objects };
}

1;
