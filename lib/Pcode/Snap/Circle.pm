package Pcode::Snap::Circle;

use Moose;
with 'Pcode::Role::Grey';
with 'Pcode::Role::ArcLike';

use constant M_PI => 3.14159265;

has 'center' => (
    is  => 'rw',
    isa => 'Pcode::Point',
    default => sub { Pcode::Point->new( { X => 0, Y => 0 } ) },
    documentation => 'Center of the circle',
);

sub properties {
    my ( $self ) = @_;
    return [
        {
            name  => 'radius',
            label => 'Radius',
            type  => 'Num',
        },
    ];
}

sub render {
    my ( $self, $app, $cr ) = @_;
    $cr->save;

    my $r = $self->radius;

    my $center = $self->center;
    return if !$center;

    my $xo = $center->X;
    my $yo = $center->Y;

    ( $xo, $yo, $r ) = $app->translate_to_screen_coords( $xo, $yo, $r );

    $cr->arc( $xo, $yo, $r, 0, M_PI * 2 );
    $cr->set_line_width( 1 );
    $cr->set_source_rgb( $self->color );
    $cr->stroke();

    $cr->restore;
}

sub serialize {
    my ( $self ) = @_;
    return [ 'circle', [ $self->center->X, $self->center->Y, $self->radius ] ];
}

sub deserialize {
    my ( $class, $x1, $y1, $radius ) = @_;
    return $class->new(
        center => Pcode::Point->new( { X => $x1, Y => $y1 } ),
        radius => $radius,
    );
}

1;
