package Pcode::Command::Arc;

use Moose;
use Pcode::Point;

with 'Pcode::Role::ArcLike';

has 'clockwise' => (
    is  => 'rw',
    isa => 'Bool',
    default => 0,
    documentation => "Is it clockwise (false is counter clockwise)",
);

has 'hover' => (
    is  => 'rw',
    isa => 'Int',
    default => 0,
    documentation => "Is the mouse hovering over it",
);

has 'dashed' => (
    is  => 'rw',
    isa => 'Bool',
    default => 0,
    documentation => "Is the line dashed",
);

sub properties {
    my ( $self ) = @_;
    return [
        {
            name  => 'radius',
            label => 'Radius',
            type  => 'Num',
        },
        {
            name  => 'clockwise',
            label => 'Clockwise',
            type  => 'Bool',
        },
    ];
}

sub center {
    my ( $self ) = @_;

    my $start = $self->start;
    my $end   = $self->end;

    my $sx = $start->X;
    my $sy = $start->Y;

    my $ex = $end->X;
    my $ey = $end->Y;

    my $r = $self->radius;

    # q == distance between two points
    my $q = sqrt( ( $ex - $sx ) ** 2 + ( $ey - $sy ) ** 2 );

    if ( $q <= 0 ) {
        print STDERR "distance is zero\n";
    }
    return if $q <= 0;

    if ( ( $r * 2 ) < $q ) {
        $r = $q / 2;
        $self->radius( $r );
    }

    # the halfway point between the two
    my $x3 = ( $sx + $ex ) / 2;
    my $y3 = ( $sy + $ey ) / 2;

    my $xc;
    my $yc;

    if ( $self->clockwise ) {
        $xc = $x3 - sqrt( $r ** 2 - ( $q / 2 ) ** 2 ) * ( $sy - $ey ) / $q;
        $yc = $y3 - sqrt( $r ** 2 - ( $q / 2 ) ** 2 ) * ( $ex - $sx ) / $q;
    }
    else {
        $xc = $x3 + sqrt( $r ** 2 - ( $q / 2 ) ** 2 ) * ( $sy - $ey ) / $q;
        $yc = $y3 + sqrt( $r ** 2 - ( $q / 2 ) ** 2 ) * ( $ex - $sx ) / $q;
    }

    return Pcode::Point->new( { X => $xc, Y => $yc } );
}

sub parallel {
    my ( $self, $distance, $flip ) = @_;

    my $center = $self->center;
    return if !$center;

    my $anglestart = $center->angle_between( $self->start );
    my $angleend   = $center->angle_between( $self->end );

    my $neg = 1;
    $neg = 0 if !$flip && !$self->clockwise;
    $neg = 0 if $flip && $self->clockwise;

    if ( $neg ) {
        $distance = 0 - $distance;
    }

    my $startn = $self->start->point_angle_distance_from( $anglestart, $distance );
    my $endn = $self->end->point_angle_distance_from( $angleend, $distance );

    my $r = $self->radius + $distance;

    my $parallel = Pcode::Command::Arc->new( { start => $startn, end => $endn, radius => $r } );
    $parallel->clockwise( $self->clockwise );
    return $parallel;
}

sub equal {
    my ( $self, $line ) = @_;
    return ( $self->start->equal( $line->start ) && $self->end->equal( $line->end ) ) ? 1 : 0;
}

sub render {
    my ( $self, $app, $cr ) = @_;
    $cr->save;

    my $r = $self->radius;

    my $center = $self->center;
    return if !$center;

    my @color = ( 1, 1, 1 );
    if ( $self->hover ) {
        @color = ( 1, 0, 0 );
    }

    ( $r ) = $app->scale_to_screen( $r );
    my ( $new_center, $start, $end ) = $app->translate_to_screen_coords( $center, $self->start, $self->end );

    my $anglestart = $new_center->angle_between( $start );
    my $angleend   = $new_center->angle_between( $end );

    my $xo = $new_center->X;
    my $yo = $new_center->Y;

    if ( $self->dashed ) {
        my @dashes = ( 6.0, 6.0 );
        my $offset = 1;
        $cr->set_dash( $offset, @dashes );
    }

    if ( $self->clockwise ) {
        $cr->arc( $xo, $yo, $r, $anglestart, $angleend );
    }
    else {
        $cr->arc( $xo, $yo, $r, $angleend, $anglestart );
    }
    $cr->set_line_width( 1 );
    $cr->set_source_rgb( @color );
    $cr->stroke();

    $cr->restore;

    $self->start->render( $app, $cr, 0 );
    $self->end->render( $app, $cr, 1 );
}

sub serialize {
    my ( $self ) = @_;
    return [ 'arc', [ $self->start->X, $self->start->Y, $self->end->X, $self->end->Y, $self->radius, $self->clockwise ] ];
}

sub deserialize {
    my ( $class, $x1, $y1, $x2, $y2, $radius, $clockwise ) = @_;
    return $class->new(
        start     => Pcode::Point->new( { X => $x1, Y => $y1 } ),
        end       => Pcode::Point->new( { X => $x2, Y => $y2 } ),
        radius    => $radius,
        clockwise => $clockwise,
    );
}

1;
