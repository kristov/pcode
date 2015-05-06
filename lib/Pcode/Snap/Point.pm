package Pcode::Snap::Point;

use Moose;
with 'Pcode::Role::PointLike';

sub serialize {
    my ( $self ) = @_;
    return [ 'point', [ $self->X, $self->Y ] ];
}

sub deserialize {
    my ( $class, $x, $y ) = @_;
    return $class->new( {
        X => $x,
        Y => $y,
    } );
}

1;
