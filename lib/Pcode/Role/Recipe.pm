package Pcode::Role::Recipe;

use Moose::Role;

has 'app' => (
    is => 'ro',
    isa => 'Pcode::App',
    required => 1,
);

sub new_empty_path {
    my ( $self ) = @_;
    return $self->app->new_empty_path;
}

sub create_object {
    my ( $self, $type, $command, $args ) = @_;
    return $self->app->create_object( $type, $command, $args );
}

sub finish_editing_path {
    my ( $self ) = @_;
    return $self->app->finish_editing_path;
}

1;
