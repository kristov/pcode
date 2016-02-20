package Pcode::App::File::Native::V1;

use Moose;
use File::Util;
use JSON qw();

has 'app' => (
    is  => 'rw',
    isa => 'Pcode::App',
    required => 1,
    documentation => "The app state",
);

has 'json' => (
    is  => 'rw',
    isa => 'JSON',
    default => sub { JSON->new->pretty( [ 1 ] ) },
    documentation => 'Serialize using JSON',
);

has 'file' => (
    is  => 'rw',
    isa => 'File::Util',
    default => sub { return File::Util->new() },
    documentation => "File manipulation object",
);

my @APP_SETTINGS = qw(
    width
    height
    zoom
    x_offset
    y_offset
);

sub save {
    my ( $self, $file ) = @_;
    die "Version not supported for saving";
}

sub load {
    my ( $self, $file ) = @_;

    my $content = $self->file->load_file( $file );
    my $document = $self->json->decode( $content );

    for my $prop ( @APP_SETTINGS ) {
        if ( exists $document->{$prop} ) {
            $self->app->$prop( $document->{$prop} );
        }
    }

    if ( $document->{machine_center} ) {
        $self->app->machine_center->X( $document->{machine_center}->{X} );
        $self->app->machine_center->Y( $document->{machine_center}->{Y} );
    }

    if ( $document->{snaps} ) {
        $self->deserialize_snaps( $document->{snaps} );
    }

    if ( $document->{paths} ) {
        $self->app->path_groups->clear;
        my $path_group = Pcode::Path::Group->new;
        $self->deserialize_paths( $document->{paths}, $path_group );
        $self->app->path_groups->add( $path_group );
    }

    if ( $document->{drill_path} ) {
        $self->deserialize_drill_path( $document->{drill_path} );
    }
}

sub deserialize_snaps {
    my ( $self, $snaps ) = @_;

    $self->app->snaps->clear;

    for my $snap ( @{ $snaps } ) {
        my ( $name, $args ) = @{ $snap };
        my $object = $self->app->create_object( 'snap', $name, $args );
        if ( $object ) {
            $self->app->snaps->append( $object );
        }
    }
    $self->app->snaps->recalculate_points;
}

sub deserialize_drill_path {
    my ( $self, $path ) = @_;

    my @properties = qw(
        name
        depth
        overcut
    );

    my $path_object = Pcode::DrillPath->new();

    for my $prop ( @properties ) {
        $path_object->$prop( $path->{$prop} ) if $path->{$prop};
    }

    for my $command ( @{ $path->{commands} } ) {
        my ( $name, $args ) = @{ $command };
        my $object = $self->app->create_object( 'command', $name, $args );
        $path_object->append_command( $object );
    }

    $self->app->drill_path( $path_object );
}

sub deserialize_paths {
    my ( $self, $paths, $path_group ) = @_;

    my @path_properties = qw(
        name
        tool_radius
        depth
        overcut
        flip
    );

    for my $path ( @{ $paths } ) {
        
        my $path_object = Pcode::Path->new();

        for my $prop ( @path_properties ) {
            $path_object->$prop( $path->{$prop} ) if $path->{$prop};
        }

        for my $command ( @{ $path->{commands} } ) {
            my ( $name, $args ) = @{ $command };
            my $object = $self->app->create_object( 'command', $name, $args );
            $path_object->append_command( $object );
        }

        $path_group->paths->add( $path_object );
        $path_object->regenerate_tool_paths;
    }
}

1;
