package Pcode::PointList;

use Moose;
with 'Pcode::Role::List';

sub detect_point_snap {
    my ( $self, $app, $x, $y, $res ) = @_;

    my $current_point = Pcode::Point->new( { X => $x, Y => $y } );
    my $found_point;

    $self->foreach( sub {
        my ( $point ) = @_;

        if ( $point->distance( $current_point ) <= $res ) {
            $point->hover( 1 );
            if ( !$app->hover_point || !$app->hover_point->equal( $point ) ) {
                $app->invalidate;
                $app->hover_point( $point );
            }
            $found_point = $point;
        }
        else {
            $point->hover( 0 );
        }
    } );

    return $found_point;
}

1;
