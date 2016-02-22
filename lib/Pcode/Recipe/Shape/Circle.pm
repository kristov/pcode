package Pcode::Recipe::Shape::Circle;

use Moose;
with 'Pcode::Role::Recipe';

use Pcode::Point;

has 'diameter' => (
    is      => 'rw',
    isa     => 'Num',
    default => 10,
    documentation => 'Diameter of the circle',
);

has 'X' => (
    is      => 'rw',
    isa     => 'Num',
    default => 0,
    documentation => 'X axis location',
);

has 'Y' => (
    is      => 'rw',
    isa     => 'Num',
    default => 0,
    documentation => 'Y axis location',
);

has 'name' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Circle',
    documentation => 'Path group name',
);

sub properties {
    my ( $self ) = @_;
    return [
        {
            name  => 'diameter',
            label => 'Circle diameter',
            type  => 'Num',
        },
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
    ];
}

sub create {
    my ( $self ) = @_;

    my $path = $self->new_path( "Circle" );

    my $X = $self->X;
    my $Y = $self->Y;

    my $d = $self->diameter;
    my $r = $d / 2;

    my $top_point = Pcode::Point->new( {
        X => $X,
        Y => $Y - $r,
    } );

    my $bottom_point = Pcode::Point->new( {
        X => $X,
        Y => $Y + $r,
    } );

    my $arc1 = $self->create_object( 'command', 'arc', [
        $top_point->X, $top_point->Y,
        $bottom_point->X, $bottom_point->Y,
        $r, 1
    ] );

    my $arc2 = $self->create_object( 'command', 'arc', [
        $bottom_point->X, $bottom_point->Y,
        $top_point->X, $top_point->Y,
        $r, 1
    ] );

    $path->append_command( $arc1 );
    $path->append_command( $arc2 );

    $self->finish_editing;
}

1;
