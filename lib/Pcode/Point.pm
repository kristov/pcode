package Pcode::Point;

use Moose;
with 'Pcode::Role::PointLike';

use constant M_PI => 3.14159265;

sub properties {
    my ( $self ) = @_;
    return [
        {
            name  => 'X',
            label => 'X',
            type  => 'Num',
        },
        {
            name  => 'Y',
            label => 'Y',
            type  => 'Num',
        },
        {
            name  => 'Z',
            label => 'Z',
            type  => 'Num',
        },
    ];
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
