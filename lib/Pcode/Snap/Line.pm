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

    my ( $start, $end ) = $app->translate_to_screen_coords( $self->start, $self->end );

    my $sx = $start->X;
    my $sy = $start->Y;

    my $ex = $end->X;
    my $ey = $end->Y;

    $cr->move_to( $sx, $sy );
    $cr->line_to( $ex, $ey );
    $cr->set_line_width( 1 );
    $cr->set_source_rgb( $self->color );
    $cr->stroke();

    $cr->restore;
}

sub serialize {
    my ( $self ) = @_;
    return [ 'line', [ $self->start->X, $self->start->Y, $self->end->X, $self->end->Y ] ];
}

sub deserialize {
    my ( $class, $x1, $y1, $x2, $y2 ) = @_;
    return $class->new(
        start => Pcode::Point->new( { X => $x1, Y => $y1 } ),
        end   => Pcode::Point->new( { X => $x2, Y => $y2 } ),
    );
}

1;
