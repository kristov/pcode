package Pcode::Role::ArcLike;

use Moose::Role;

use constant M_PI => 3.14159265;

has 'start' => (
    is  => 'rw',
    isa => 'Pcode::Point',
    default => sub { Pcode::Point->new( { X => 0, Y => 0 } ) },
    documentation => "Start point",
);

has 'end' => (
    is  => 'rw',
    isa => 'Pcode::Point',
    default => sub { Pcode::Point->new( { X => 10, Y => 10 } ) },
    documentation => "End point",
);

has 'radius' => (
    is  => 'rw',
    isa => 'Num',
    documentation => "Radius",
);

around 'radius' => sub {
    my ( $orig, $self, $r ) = @_;

    return $self->$orig() if !defined $r;

    if ( $self->dashed ) {
        return $self->$orig( $r );
    }

    my $start = $self->start;
    my $end   = $self->end;

    my $sx = $start->X;
    my $sy = $start->Y;

    my $ex = $end->X;
    my $ey = $end->Y;

    my $q = sqrt( ( $ex - $sx ) ** 2 + ( $ey - $sy ) ** 2 );

    if ( ( $r * 2 ) < $q ) {
        $r = $q / 2;
    }

    return $self->$orig( $r );
};

sub intersect {
    my ( $self, $object ) = @_;
    if ( $object->does( 'Pcode::Role::LineLike' ) ) {
        return $self->intersection_line( $object );
    }
    elsif ( $object->does( 'Pcode::Role::ArcLike' ) ) {
        return $self->intersection_arc( $object );
    }
    return ();
}

sub distance_to_point {
    my ( $self, $point ) = @_;

    my $px = $self->end->X - $self->start->X;
    my $py = $self->end->Y - $self->start->Y;

    my $something = ( $px * $px ) + ( $py * $py );

    my $u = ( ( $point->X - $self->start->X ) * $px + ( $point->Y - $self->start->Y ) * $py) / $something;

    if ( $u > 1 ) {
        $u = 1;
    }
    elsif ( $u < 0 ) {
        $u = 0;
    }

    my $x = $self->start->X + $u * $px;
    my $y = $self->start->Y + $u * $py;

    my $dx = $x - $point->X;
    my $dy = $y - $point->Y;

    my $dist = sqrt( ( $dx * $dx ) + ( $dy * $dy ) );

    return $dist;
}

sub point_within_arc {
    my ( $self, $point ) = @_;

    my $start  = $self->start;
    my $end    = $self->end;
    my $center = $self->center;

    my $start_angle = $center->angle_between( $start );
    my $end_angle   = $center->angle_between( $end );
    my $point_angle = $center->angle_between( $point );

    my $twopi = M_PI * 2;

    $start_angle = $twopi + $start_angle if $start_angle < 0;
    $end_angle   = $twopi + $end_angle   if $end_angle   < 0;
    $point_angle = $twopi + $point_angle if $point_angle < 0;

    my $result = 0;
    my $larger_angle;
    my $smaller_angle;
    if ( $start_angle > $end_angle ) {
        $larger_angle = $start_angle;
        $smaller_angle = $end_angle;
    }
    else {
        $larger_angle = $end_angle;
        $smaller_angle = $start_angle;
    }
    $result = 1 if $point_angle >= $smaller_angle && $point_angle <= $larger_angle;

    return $result;
}

sub intersection_arc {
    my ( $self, $arc ) = @_;

    my $scenter = $self->center;
    my $acenter  = $arc->center;

    my $x0 = $scenter->X;
    my $y0 = $scenter->Y;

    my $x1 = $acenter->X;
    my $y1 = $acenter->Y;

    my $d = $scenter->distance( $acenter );

    my $sr = $self->radius;
    my $ar  = $arc->radius;

    # dx and dy are the vertical and horizontal distances between
    # the circle centers.
    my $dx = $x1 - $x0;
    my $dy = $y1 - $y0;

    if ( $d > ( $sr + $ar ) ) {
        # no solution. circles do not intersect
        return ();
    }

    my $pd = ( $sr > $ar ) ? ( $sr - $ar ) : ( $ar - $sr );
    if ( $d <= $pd ) {
        # no solution. one circle is contained in the other
        return ();
    }

    # 'point 2' is the point where the line through the circle
    # intersection points crosses the line between the circle
    # centers.

    # Determine the distance from point 0 to point 2
    my $a = ( ( $sr * $sr ) - ( $ar * $ar ) + ( $d * $d ) ) / ( 2 * $d );

    # Determine the coordinates of point 2
    my $x2 = $x0 + ( $dx * $a / $d );
    my $y2 = $y0 + ( $dy * $a / $d );

    # Determine the distance from point 2 to either of the
    # intersection points.
    my $h = sqrt( ( $sr * $sr ) - ( $a * $a ) );

    # Now determine the offsets of the intersection points from
    # point 2.
    my $rx = 0 - ( $dy * ( $h / $d ) );
    my $ry = $dx * ( $h / $d );

    my $xi = $x2 + $rx;
    my $yi = $y2 + $ry;

    my $xi_prime = $x2 - $rx;
    my $yi_prime = $y2 - $ry;

    my $point1 = Pcode::Point->new( { X => $xi, Y => $yi } );
    my $point2 = Pcode::Point->new( { X => $xi_prime, Y => $yi_prime } );

    return ( $point1, $point2 );
}

sub intersection_line {
    my ( $self, $line ) = @_;

    my $ls = $line->start;
    my $le = $line->end;

    my $r = $self->radius;
    my $c = $self->center;

    my $lab = $ls->distance( $le );

    my $dx = ( $le->X - $ls->X ) / $lab;
    my $dy = ( $le->Y - $ls->Y ) / $lab;

    my $t = $dx * ( $c->X - $ls->X ) + $dy * ( $c->Y - $ls->Y );

    my $ex = ( $t * $dx ) + $ls->X;
    my $ey = ( $t * $dy ) + $ls->Y;

    my $lec = sqrt( ( $ex - $c->X ) ** 2 + ( $ey - $c->Y ) ** 2 );

    if ( $lec < $r ) {
        my $dt = sqrt( $r ** 2 - $lec ** 2 );

        my $fx = ( $t - $dt ) * $dx + $ls->X;
        my $fy = ( $t - $dt ) * $dy + $ls->Y;

        my $gx = ( $t + $dt ) * $dx + $ls->X;
        my $gy = ( $t + $dt ) * $dy + $ls->Y;

        return (
            Pcode::Point->new( { X => $fx, Y => $fy } ),
            Pcode::Point->new( { X => $gx, Y => $gy } ),
        );
    }
    elsif ( $lec == $r ) {
        return (
            Pcode::Point->new( { X => $ex, Y => $ey } ),
        );
    }
}

1;
