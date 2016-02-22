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
    lazy => 1,
    builder => '_build_path_group',
    documentation => 'The path group for the object',
);

sub _build_path_group {
    my ( $self ) = @_;
    my $name = "Unnamed object";
    $name = $self->name if $self->can( 'name' );
    return Pcode::Path::Group->new( { name => $name } );
}

sub new_path {
    my ( $self, $name ) = @_;
    return $self->path_group->new_path( $name );
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
