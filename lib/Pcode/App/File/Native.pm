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

sub save {
    my ( $self ) = @_;

    my $document = {};

    if ( $self->app->snaps ) {
        $self->serialize_snaps( $document );
    }

    if ( $self->app->paths ) {
        $self->serialize_paths( $document );
    }

    my $string = $self->json->encode( $document );

    $self->file->write_file( file => './working.pcode', content => $string );
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

sub load {
    my ( $self, $file ) = @_;

    my $string = $self->file->load_file( $file );

    my $document = $self->json->decode( $string );

    if ( $document->{snaps} ) {
        $self->deserialize_snaps( $document->{snaps} );
    }

    if ( $document->{paths} ) {
        $self->deserialize_paths( $document->{paths} );
    }
}

sub deserialize_snaps {
    my ( $self, $snaps ) = @_;

    $self->app->snaps->clear;

    for my $snap ( @{ $snaps } ) {
        my ( $name, $args ) = @{ $snap };
        my $object = $self->app->create_object( 'snap', $name, $args );
        $self->app->snaps->append( $object );
    }

    $self->app->update_code_window;
}

sub deserialize_paths {
    my ( $self, $paths ) = @_;

    $self->app->paths->clear;

    my $first_path;
    for my $path ( @{ $paths } ) {
        
        my $path_object = Pcode::Path->new();
        $first_path = $path_object if !$first_path;

        for my $command ( @{ $path->{commands} } ) {
            my ( $name, $args ) = @{ $command };
            my $object = $self->app->create_object( 'command', $name, $args );
            $path_object->append_command( $object );
        }

        $self->app->paths->add( $path_object );
    }

    if ( !$first_path ) {
        $first_path = Pcode::Path->new();
        $self->app->paths->add( $first_path );
    }

    $self->app->current_path( $first_path );
}

1;
