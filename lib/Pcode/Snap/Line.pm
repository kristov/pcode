package Pcode::Snap::Line;

use Moose;
with 'Pcode::Role::Grey';
with 'Pcode::Role::LineLike';

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

    ( $sx, $sy, $ex, $ey ) = $app->translate_to_screen_coords( $sx, $sy, $ex, $ey );

    $cr->move_to( $sx, $sy );
    $cr->line_to( $ex, $ey );
    $cr->set_line_width( 1 );
    $cr->set_source_rgb( $self->color );
    $cr->stroke();

    $cr->restore;
}

sub stringify {
    my ( $self ) = @_;
    return sprintf(
        'line([%0.4f,%0.4f],[%0.4f,%0.4f])',
        $self->start->X, $self->start->Y,
        $self->end->X, $self->end->Y,
    );
}

1;
