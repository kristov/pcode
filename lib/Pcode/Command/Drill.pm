package Pcode::Command::Drill;

use Moose;
with 'Pcode::Role::PointLike';

has 'clockwise' => (
    is  => 'rw',
    isa => 'Bool',
    default => 0,
    documentation => "Is it clockwise (false is counter clockwise)",
);

has 'hover' => (
    is  => 'rw',
    isa => 'Int',
    default => 0,
    documentation => "Is the mouse hovering over it",
);

has 'start' => (
    is  => 'rw',
    isa => 'Pcode::Point',
    lazy => 1,
    builder => '_build_start',
);

has 'end' => (
    is  => 'rw',
    isa => 'Pcode::Point',
    lazy => 1,
    builder => '_build_end',
);

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
    ];
}

sub _build_start {
    my ( $self ) = @_;
    return Pcode::Point->new( X => $self->X, Y => $self->Y );
}

sub _build_end {
    my ( $self ) = @_;
    return Pcode::Point->new( X => $self->X, Y => $self->Y );
}

sub parallel {
    my ( $self ) = @_;
    return $self;
}

sub render {
    my ( $self, $app, $cr ) = @_;
    $cr->save;

    my ( $screen ) = $app->translate_to_screen_coords( $self );

    my $x = $screen->X;
    my $y = $screen->Y;

    my $x1 = $x - 10;
    my $x2 = $x + 10;

    my $y1 = $y - 10;
    my $y2 = $y + 10;

    $cr->set_line_width( 1 );
    $cr->set_source_rgb( 0, 1, 1 );

    $cr->move_to( $x1, $y );
    $cr->line_to( $x2, $y );
    $cr->stroke();

    $cr->move_to( $x, $y1 );
    $cr->line_to( $x, $y2 );
    $cr->stroke();

    $cr->restore;
}

sub serialize {
    my ( $self ) = @_;
    return [ 'drill', [ $self->X, $self->Y ] ];
}

sub deserialize {
    my ( $class, $x, $y ) = @_;
    return $class->new(
        X => $x,
        Y => $y,
    );
}

__PACKAGE__->meta->make_immutable;
