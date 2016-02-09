package Pcode::Recipe::Shape::Box;

use Moose;
with 'Pcode::Role::Recipe';

use Pcode::Point;

has 'width' => (
    is      => 'rw',
    isa     => 'Num',
    default => 20,
    documentation => 'Width',
);

has 'height' => (
    is      => 'rw',
    isa     => 'Num',
    default => 20,
    documentation => 'Height',
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

sub properties {
    my ( $self ) = @_;
    return [
        {
            name  => 'width',
            label => 'Width',
            type  => 'Num',
        },
        {
            name  => 'height',
            label => 'Height',
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

    my $path = $self->new_empty_path;
    $path->name( "Box" );

    my $X = $self->X;
    my $Y = $self->Y;

    my $w = $self->width;
    my $h = $self->height;

    my $top = $self->create_object( 'command', 'line', [ $X, $Y, $X + $w, $Y ] );
    my $rig = $self->create_object( 'command', 'line', [ $X + $w, $Y, $X + $w, $Y + $h ] );
    my $bot = $self->create_object( 'command', 'line', [ $X + $w, $Y + $h, $X, $Y + $h ] );
    my $lef = $self->create_object( 'command', 'line', [ $X, $Y + $h, $X, $Y ] );

    $path->append_command( $top );
    $path->append_command( $rig );
    $path->append_command( $bot );
    $path->append_command( $lef );

    $self->finish_editing_path;
}

1;
