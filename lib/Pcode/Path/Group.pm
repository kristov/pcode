package Pcode::Path::Group;

use Moose;
use Pcode::Path::List;
use Pcode::Path;

has 'paths' => (
    is  => 'rw',
    isa => 'Pcode::Path::List',
    default => sub { Pcode::Path::List->new(); },
    documentation => "List of paths",
);

has 'name' => (
    is  => 'rw',
    isa => 'Str',
    default => 'New Path Group',
);

has '_current_path' => (
    is  => 'rw',
    isa => 'Pcode::Path',
    documentation => "Working path",
);

sub current_path {
    my ( $self ) = @_;
    if ( !$self->_current_path ) {
        my $path = Pcode::Path->new( { name => "New path" } );
        $self->paths->append( $path );
        $self->_current_path( $path );
    }
    return $self->_current_path;
}

sub set_current_path {
    my ( $self, $path ) = @_;
    $self->_current_path( $path );
}

sub delete_last_path {
    my ( $self ) = @_;
    $self->pop;
    return $self->last;
}

sub delete_path {
    my ( $self, $path ) = @_;
    return $self->delete_this( $path );
}

sub new_path {
    my ( $self, $name ) = @_;
    my $path = Pcode::Path->new( { name => $name || "New path" } );
    $self->paths->append( $path );
    $self->_current_path( $path );
}

sub delete_last_command {
    my ( $self ) = @_;
    $self->current_path->delete_last;
    # Wrong, always assumes the current_path is the last
    if ( $self->current_path->nr_commands == 0 ) {
        if ( $self->paths->nr_paths > 1 ) {
            my $prev_path = $self->paths->delete_last_path;
            $self->current_path( $prev_path );
        }
    }
}

sub delete_current_path {
    my ( $self ) = @_;

    my $current_path = $self->_current_path;
    return unless $current_path;

    my $prev_path = $self->paths->delete_path( $current_path );

    if ( $prev_path ) {
        $self->_current_path( $prev_path );
    }
}

sub clear_all {
    my ( $self ) = @_;
    if ( $self->_current_path ) {
        $self->_current_path->clear;
    }
}

sub bounding_points {
    my ( $self ) = @_;

    my $minx;
    my $miny;
    my $maxx;
    my $maxy;

    return if $self->count == 0;

    $self->paths->foreach( sub {
        my ( $path ) = @_;
        my ( $pmin, $pmax ) = $path->bounding_points;
        return if !$pmax;
        $minx = $pmin->X if !defined $minx || $pmin->X < $minx;
        $miny = $pmin->Y if !defined $miny || $pmin->Y < $miny;
        $maxx = $pmax->X if !defined $maxx || $pmax->X > $maxx;
        $maxy = $pmax->Y if !defined $maxy || $pmax->Y > $maxy;
    } );

    return if ( !defined $minx || !defined $miny || !defined $maxx || !defined $maxy );

    return (
        Pcode::Point->new( { X => $minx, Y => $miny } ),
        Pcode::Point->new( { X => $maxx, Y => $maxy } ),
    );
}
sub serialize {
    my ( $self ) = @_;

    my $paths_serialized = [];

    $self->paths->foreach( sub {
        my ( $path ) = @_;
        push @{ $paths_serialized }, $path->serialize;
    } );

    return {
        name  => $self->name,
        paths => $paths_serialized,
    };
}

1;
