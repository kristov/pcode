package Pcode::App::File::Native;

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

has 'default_working_file' => (
    is  => 'rw',
    isa => 'Str',
    default => '.working.pcode',
    documentation => 'The default working file',
);

my @APP_SETTINGS = qw(
    width
    height
    zoom
    x_offset
    y_offset
);

sub save_tmp {
    my ( $self ) = @_;
    $self->save( $self->default_working_file );
}

sub save {
    my ( $self, $file ) = @_;

    my $document = {};

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

    if ( $self->app->paths ) {
        $self->serialize_paths( $document );
    }

    if ( $self->app->drill_path ) {
        $self->serialize_drill_path( $document );
    }

    my $string = $self->json->encode( $document );

    $self->file->write_file(
        file    => $file,
        content => $string,
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

sub serialize_paths {
    my ( $self, $document ) = @_;

    $document->{paths} ||= [];
    my $object = $document->{paths};

    $self->app->paths->foreach( sub {
        my ( $path ) = @_;
        push @{ $object }, $path->serialize;
    } );
}

sub serialize_drill_path {
    my ( $self, $document ) = @_;
    $document->{drill_path} = $self->app->drill_path->serialize;
}

sub working_file_exists {
    my ( $self ) = @_;
    return $self->file->existent( $self->default_working_file );
}

sub load_working_file {
    my ( $self ) = @_;
    if ( $self->working_file_exists ) {
        $self->load( $self->default_working_file );
    }
}

sub load {
    my ( $self, $file ) = @_;

    my $string = $self->file->load_file( $file );

    my $document = $self->json->decode( $string );

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
        $self->deserialize_paths( $document->{paths} );
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
    my ( $self, $paths ) = @_;

    $self->app->paths->clear;

    my @path_properties = qw(
        name
        tool_radius
        depth
        overcut
        flip
    );

    my $first_path;
    for my $path ( @{ $paths } ) {
        
        my $path_object = Pcode::Path->new();
        $first_path = $path_object if !$first_path;

        for my $prop ( @path_properties ) {
            $path_object->$prop( $path->{$prop} ) if $path->{$prop};
        }

        for my $command ( @{ $path->{commands} } ) {
            my ( $name, $args ) = @{ $command };
            my $object = $self->app->create_object( 'command', $name, $args );
            $path_object->append_command( $object );
        }

        $self->app->paths->add( $path_object );
        $path_object->regenerate_tool_paths;
    }

    if ( !$first_path ) {
        $first_path = Pcode::Path->new();
        $self->app->paths->add( $first_path );
    }

    $self->app->current_path( $first_path );
}

1;
