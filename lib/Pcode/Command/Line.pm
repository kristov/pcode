package Pcode::Command::Line;

use Moose;

extends 'Pcode::Command';

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

use constant M_PI => 3.14159265;

sub distance_to_point {
    my ( $self, $point ) = @_;

    my $px = $self->end->X - $self->start->X;
    my $py = $self->end->Y - $self->start->Y;

    my $something = ( $px * $px ) + ( $py * $py );
    return 0 if $something == 0;

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

sub intersection_line {
    my ( $self, $line ) = @_;

    my $ss = $self->start;
    my $se = $self->end;

    my $ls = $line->start;
    my $le = $line->end;

=item

   function doLineSegmentsIntersect(p, p2, q, q2) {
    var r = subtractPoints(p2, p);
    var s = subtractPoints(q2, q);

    var uNumerator = crossProduct(subtractPoints(q, p), r);
    var denominator = crossProduct(r, s);

    if (uNumerator == 0 && denominator == 0) {
        // They are coLlinear
        
        // Do they touch? (Are any of the points equal?)
        if (equalPoints(p, q) || equalPoints(p, q2) || equalPoints(p2, q) || equalPoints(p2, q2)) {
            return true
        }
        // Do they overlap? (Are all the point differences in either direction the same sign)
        // Using != as exclusive or
        return ((q.x - p.x < 0) != (q.x - p2.x < 0) != (q2.x - p.x < 0) != (q2.x - p2.x < 0)) || 
            ((q.y - p.y < 0) != (q.y - p2.y < 0) != (q2.y - p.y < 0) != (q2.y - p2.y < 0));
    }

    if (denominator == 0) {
        // lines are paralell
        return false;
    }

    var u = uNumerator / denominator;
    var t = crossProduct(subtractPoints(q, p), s) / denominator;

    return (t >= 0) && (t <= 1) && (u >= 0) && (u <= 1);

=cut

}

sub parallel {
    my ( $self, $distance ) = @_;

    my $angle = $self->start->angle_between( $self->end );
    my $tangent = $angle + ( M_PI / 2 );

    my $startn = $self->start->point_angle_distance_from( $tangent, $distance );
    my $endn = $self->end->point_angle_distance_from( $tangent, $distance );

    return Pcode::Command::Line->new( { start => $startn, end => $endn } );
}

sub equal {
    my ( $self, $line ) = @_;
    return ( $self->start->equal( $line->start ) && $self->end->equal( $line->end ) ) ? 1 : 0;
}

sub render {
    my ( $self, $app, $cr ) = @_;
    $cr->save;

    my $start = $self->start;
    my $end   = $self->end;

    my $sx = $start->X;
    my $sy = $start->Y;

    my $ex = $end->X;
    my $ey = $end->Y;

    my @color = ( 1, 1, 1 );
    if ( $self->hover ) {
        @color = ( 1, 0, 0 );
    }

    ( $sx, $sy, $ex, $ey ) = $app->translate_to_screen_coords( $sx, $sy, $ex, $ey );

    if ( $self->dashed ) {
        my @dashes = ( 6.0, 6.0 );
        my $offset = 1;
        $cr->set_dash( $offset, @dashes );
    }

    $cr->move_to( $sx, $sy );
    $cr->line_to( $ex, $ey );
    $cr->set_line_width( 2 );
    $cr->set_source_rgb( @color );
    $cr->stroke();

    $cr->restore;

    $start->render( $app, $cr, 0 );
    $end->render( $app, $cr, 1 );
}

1;
