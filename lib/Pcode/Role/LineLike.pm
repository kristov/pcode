package Pcode::Role::LineLike;

use Moose::Role;

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

sub equal {
    my ( $self, $line ) = @_;
    return ( $self->start->equal( $line->start ) && $self->end->equal( $line->end ) ) ? 1 : 0;
}

1;
