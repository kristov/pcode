package Pcode::Util::Coord;

use Moose;
use Pcode::Point;

has 'x_offset' => (
    is  => 'rw',
    isa => 'Num',
    default => 10,
    documentation => "Viewing window offset X",
);

has 'y_offset' => (
    is  => 'rw',
    isa => 'Num',
    default => 10,
    documentation => "Viewing window offset Y",
);

has 'zoom' => (
    is  => 'rw',
    isa => 'Num',
    default => 0,
    documentation => "Viewing window zoom",
);

sub zoom_in {
    my ( $self ) = @_;
    my $zoom = $self->zoom;
    $zoom++;
    $self->zoom( $zoom );
}

sub zoom_out {
    my ( $self ) = @_;
    my $zoom = $self->zoom;
    $zoom--;
    $self->zoom( $zoom );
}

sub scale_to_screen {
    my ( $self, @numbers ) = @_;
    my $zoom = $self->zoom;
    return @numbers if $zoom == 0;
    @numbers = map { $_ * $zoom } @numbers;
    return @numbers;
}

sub scale_from_screen {
    my ( $self, @numbers ) = @_;
    my $zoom = $self->zoom;
    return @numbers if $zoom == 0;
    @numbers = map { $_ / $zoom } @numbers;
    return @numbers;
}

sub translate_to_screen_coords {
    my ( $self, $height, @points ) = @_;

    my @new_points;

    for my $point ( @points ) {
        my ( $x, $y ) = ( $point->X, $point->Y );
        ( $x, $y ) = $self->scale_to_screen( $x, $y );
        my ( $x_offset, $y_offset ) = $self->scale_to_screen( $self->x_offset, $self->y_offset );
        $x = $x - $x_offset;
        $y = $y - $y_offset;
        $y = $height - $y;
        push @new_points, Pcode::Point->new( { X => $x, Y => $y } );
    }
    return @new_points;
}

sub translate_from_screen_coords {
    my ( $self, $height, @points ) = @_;
    
    my @new_points;

    for my $point ( @points ) {
        my ( $x, $y ) = ( $point->X, $point->Y );
        $y = $height - $y;
        my ( $x_offset, $y_offset ) = $self->scale_to_screen( $self->x_offset, $self->y_offset );
        $x = $x + $x_offset;
        $y = $y + $y_offset;
        ( $x, $y ) = $self->scale_from_screen( $x, $y );
        push @new_points, Pcode::Point->new( { X => $x, Y => $y } );
    }
    return @new_points;
}

__PACKAGE__->meta->make_immutable;
