package Gcode::Path;

use Moose;

has path => (
    is  => 'rw',
    isa => 'ArrayRef',
    default => sub { [ ] },
    documentation => 'The commands making up a path',
);

has name => (
    is  => 'rw',
    isa => 'Str',
    documentation => 'The path name',
);

has start_X => (
    is  => 'rw',
    isa => 'Num',
    default => 0,
    documentation => 'The path starting X',
);

has start_Y => (
    is  => 'rw',
    isa => 'Num',
    default => 0,
    documentation => 'The path starting Y',
);

sub set_start_position {
    my ( $self, $X, $Y ) = @_;
    $self->start_X( $X );
    $self->start_Y( $Y );
}

sub add_command {
    my ( $self, $command ) = @_;
    my $path = $self->path;
    push @{ $path }, $command;
    $self->path( $path );
}

sub foreach {
    my ( $self, $code ) = @_;
    my $list = $self->path;
    my $last;
    for my $item ( @{ $list } ) {
        $code->( $item, $last );
        $last = $item;
    }
    return $last;
}

1;
