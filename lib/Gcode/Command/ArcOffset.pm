package Gcode::Command::ArcOffset;

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

has I => (
    is  => 'rw',
    isa => 'Num',
    required => 1,
);

has J => (
    is  => 'rw',
    isa => 'Num',
    required => 1,
);

has clockwise => (
    is  => 'rw',
    isa => 'Bool',
    required => 1,
);

has feed_rate => (
    is  => 'rw',
    isa => 'Int',
    default => 200,
);

sub gcode {
    my ( $self ) = @_;
    my $code = $self->clockwise ? '2' : '3';
    return sprintf( "G%d X%0.3f Y%0.3f I%0.3f J%0.3f F%d", $code, $self->X, $self->Y, $self->I, $self->J, $self->feed_rate );
}

1;
