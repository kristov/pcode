package Pcode::App::File::Native::V2;

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

    my $document = { version => "V2" };

    for my $prop ( @APP_SETTINGS ) {
        $document->{$prop} = $self->app->$prop;
    }

    if ( $self->app->machine_center ) {
        $document->{machine_center} = {
            X => $self->app->machine_center->X,
            Y => $self->app->machine_center->Y,
        };
    }

    if ( $self->app->snaps ) {
        $self->serialize_snaps( $document );
    }

    if ( $self->app->path_groups ) {
        $self->serialize_path_groups( $document );
    }

    if ( $self->app->drill_path ) {
        $self->serialize_drill_path( $document );
    }

    my $content = $self->json->encode( $document );

    $self->file->write_file(
        file    => $file,
        content => $content,
        bitmask => 0644,
    );
}

sub serialize_snaps {
    my ( $self, $document ) = @_;

    $document->{snaps} ||= [];
    my $object = $document->{snaps};

    $self->app->snaps->foreach( sub {
        my ( $snap ) = @_;
        push @{ $object }, $snap->serialize;
    } );
}

sub serialize_path_groups {
    my ( $self, $document ) = @_;

    $document->{path_groups} ||= [];
    my $object = $document->{path_groups};

    $self->app->path_groups->foreach( sub {
        my ( $path_group ) = @_;
        push @{ $object }, $path_group->serialize;
    } );
}

sub serialize_drill_path {
    my ( $self, $document ) = @_;
    $document->{drill_path} = $self->app->drill_path->serialize;
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

    if ( $document->{path_groups} ) {
        $self->deserialize_path_groups( $document->{path_groups} );
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

sub deserialize_path_groups {
    my ( $self, $path_groups ) = @_;

    $self->app->path_groups->clear;

    for my $path_group ( @{ $path_groups } ) {
        my $path_group_obj = Pcode::Path::Group->new( { name => $path_group->{name} } );
        $self->deserialize_paths( $path_group->{paths}, $path_group_obj );
        $self->app->path_groups->add( $path_group_obj );
    }
}

sub deserialize_paths {
    my ( $self, $paths, $path_group_obj ) = @_;

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

        $path_group_obj->paths->add( $path_object );
        $path_object->regenerate_tool_paths;
    }
}

1;
