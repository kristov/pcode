package Pcode::Role::PointLike;

use Moose::Role;

has 'X' => (
    is  => 'rw',
    isa => 'Num',
    default => 0,
    documentation => "X position",
);

has 'Y' => (
    is  => 'rw',
    isa => 'Num',
    default => 0,
    documentation => "X position",
);

has 'Z' => (
    is  => 'rw',
    isa => 'Num',
    default => 0,
    documentation => "X position",
);

has 'hover' => (
    is  => 'rw',
    isa => 'Int',
    default => 0,
    documentation => "Is the mouse hovering over it",
);

use constant M_PI => 3.14159265;

sub distance {
    my ( $self, $point ) = @_;

    my ( $x1, $y1 ) = ( $self->X, $self->Y );
    my ( $x2, $y2 ) = ( $point->X, $point->Y );

    my $q = sqrt( ( $x2 - $x1 ) ** 2 + ( $y2 - $y1 ) ** 2 );

    return $q;
}

sub point_angle_distance_from {
    my ( $self, $angle, $distance ) = @_;

    my $x = ( $distance * cos( $angle ) ) + $self->X;
    my $y = ( $distance * sin( $angle ) ) + $self->Y;

    return Pcode::Point->new( { X => $x, Y => $y } );
}

sub angle_between {
    my ( $self, $point ) = @_;
    return atan2( ( $point->Y - $self->Y ), ( $point->X - $self->X ) );
}

sub equal {
    my ( $self, $point ) = @_;
    return ( $self->X == $point->X && $self->Y == $point->Y && $self->Z == $point->Z ) ? 1 : 0;
}

sub translate {
    my ( $self, $x, $y ) = @_;
    my $xs = $self->X;
    my $ys = $self->Y;
    $self->X( $xs + $x );
    $self->Y( $ys + $y );
}

sub render {
    my ( $self, $app, $cr, $square ) = @_;
    $cr->save;

    my @color = ( 1, 1, 1 );
    if ( $self->hover ) {
        @color = ( 1, 0, 0 );
    }

    my ( $point ) = $app->translate_to_screen_coords( $self );

    my $x = $point->X;
    my $y = $point->Y;

    if ( $square ) {
        $cr->rectangle( $x - 5, $y - 5, 10, 10 );
    }
    else {
        $cr->arc( $x, $y, 5, 0, 2 * M_PI );
    }
    $cr->set_line_width( 1 );
    $cr->set_source_rgb( @color );
    $cr->stroke();

    $cr->restore;
}

1;
