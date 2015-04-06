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

sub intersect {
    my ( $self, $object ) = @_;
    if ( $object->does( 'Pcode::Role::LineLike' ) ) {
        return $self->intersection_line( $object );
    }
    elsif ( $object->does( 'Pcode::Role::ArcLike' ) ) {
        return $object->intersection_line( $self );
    }
    return ();
}

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

    my $ssx = $ss->X;
    my $ssy = $ss->Y;

    my $sex = $se->X;
    my $sey = $se->Y;

    my $lsx = $ls->X;
    my $lsy = $ls->Y;

    my $lex = $ls->X;
    my $ley = $ls->Y;

    my $s1x = $se->X - $ss->X;
    my $s1y = $se->Y - $ss->Y;

    my $s2x = $le->X - $ls->X;
    my $s2y = $le->Y - $ls->Y;

    my $something = ( -$s2x * $s1y + $s1x * $s2y );
    return () if $something == 0;

    my $s = ( -$s1y * ( $ss->X - $ls->X ) + $s1x * ( $ss->Y - $ls->Y ) ) / $something;
    my $t = (  $s2x * ( $ss->Y - $ls->Y ) - $s2y * ( $ss->X - $ls->X ) ) / $something;

    if ( $s >= 0 && $s <= 1 && $t >= 0 && $t <= 1 ) {
        my $ix = $ss->X + ( $t * $s1x );
        my $iy = $ss->Y + ( $t * $s1y );
        return Pcode::Point->new( { X => $ix, Y => $iy } );
    }

    return ();
}

sub intersection_imaginary_line {
    my ( $self, $line ) = @_;

    my $ss = $self->start;
    my $se = $self->end;

    my $ls = $line->start;
    my $le = $line->end;

    my $a1 = $se->Y - $ss->Y;
    my $b1 = $ss->X - $se->X;

    my $a2 = $le->Y - $ls->Y;
    my $b2 = $ls->X - $le->X;

    my $c1 = ( $a1 * $ss->X ) + ( $b1 * $ss->Y );
    my $c2 = ( $a2 * $ls->X ) + ( $b2 * $ls->Y );

    my $det = ( $a1 * $b2 ) - ( $a2 * $b1 );

    if ( $det != 0 ) {
        my $x = ( $b2 * $c1 - $b1 * $c2 ) / $det;
        my $y = ( $a1 * $c2 - $a2 * $c1 ) / $det;
        return Pcode::Point->new( { X => $x, Y => $y } );
    }

    return ();
}

sub equal {
    my ( $self, $line ) = @_;
    return ( $self->start->equal( $line->start ) && $self->end->equal( $line->end ) ) ? 1 : 0;
}

sub translate {
    my ( $self, $x, $y ) = @_;
    $self->start->translate( $x, $y );
    $self->end->translate( $x, $y );
}

1;
