package Pcode::Command::Line;

use Moose;
with 'Pcode::Role::LineLike';

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

sub parallel {
    my ( $self, $distance ) = @_;

    my $angle = $self->start->angle_between( $self->end );
    my $tangent = $angle + ( M_PI / 2 );

    my $startn = $self->start->point_angle_distance_from( $tangent, $distance );
    my $endn = $self->end->point_angle_distance_from( $tangent, $distance );

    return Pcode::Command::Line->new( { start => $startn, end => $endn } );
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

sub stringify {
    my ( $self ) = @_;
    return sprintf(
        'line([%0.4f,%0.4f],[%0.4f,%0.4f])',
        $self->start->X, $self->start->Y,
        $self->end->X, $self->end->Y,
    );
}

1;
