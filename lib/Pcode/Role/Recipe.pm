package Pcode::Role::Recipe;

use Moose::Role;

has 'app' => (
    is => 'ro',
    isa => 'Pcode::App',
    required => 1,
);

has 'path_group' => (
    is => 'ro',
    isa => 'Pcode::Path::Group',
    default => sub { return Pcode::Path::Group->new; },
);

sub new_path {
    my ( $self ) = @_;
    return $self->path_group->new_path;
}

sub create_object {
    my ( $self, $type, $command, $args ) = @_;
    return $self->app->create_object( $type, $command, $args );
}

sub finish_editing {
    my ( $self ) = @_;
    $self->app->add_path_group( $self->path_group );
    $self->app->finish_editing_path;
}

1;
