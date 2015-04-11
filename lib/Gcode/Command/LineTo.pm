package Gcode::Command::LineTo;

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

sub gcode {
    my ( $self ) = @_;
    return sprintf( "G1 X%0.3f Y%0.3f F%d", $self->X, $self->Y, $self->feed_rate );
}

1;
