package Pcode::PathList;

use Moose;
use Pcode::Path;
with 'Pcode::Role::List';

sub new_path {
    my ( $self ) = @_;
    my $path = Pcode::Path->new();
    $self->append( $path );
    return $path;
}

sub nr_paths {
    my ( $self ) = @_;
    return $self->count;
}

sub delete_last_path {
    my ( $self ) = @_;
    $self->pop;
    return $self->last;
}

sub translate {
    my ( $self, $x, $y ) = @_;
    $self->foreach( sub {
        my ( $path ) = @_;
        $path->translate( $x, $y );
    } );
}

1;
