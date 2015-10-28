package Gcode::Command::Drill;

use Moose;

has X => (
    is  => 'rw',
    isa => 'Num',
    required => 1,
);

has Y => (
    is  => 'rw',
    isa => 'Num',
    required => 1,
);

has feed_rate => (
    is  => 'rw',
    isa => 'Int',
    default => 200,
);

has depth => (
    is  => 'rw',
    isa => 'Int',
    default => 0,
);

sub gcode {
    my ( $self ) = @_;
    return sprintf( "G1 Z%0.3f F%d", $self->depth, $self->feed_rate );
}

1;
