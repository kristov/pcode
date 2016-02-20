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

sub load {
    my ( $self, $file ) = @_;

    my $version = $self->detect_version( $file );
    my $state_class = $self->load_state_class( $version );

    if ( $state_class ) {
        my $loader = $state_class->new( { app => $self->app } );
        $loader->load( $file );
    }
}

sub save {
    my ( $self, $file ) = @_;

    my $latest_state_version = $self->app->latest_state_version;
    my $state_class = $self->load_state_class( $latest_state_version );

    if ( $state_class ) {
        my $saver = $state_class->new( { app => $self->app } );
        $saver->save( $file );
    }
    else {
        die "Unable to save using $state_class";
    }
}

sub load_state_class {
    my ( $self, $state_version ) = @_;
    my $class = "Pcode::App::File::Native::$state_version";
    eval "use $class; 1;" or do {
        warn $@;
    };
    return $class;
}

sub detect_version {
    my ( $self, $file ) = @_;

    my $content = $self->file->load_file( $file );
    my $version = "V1";
    if ( $content =~ /"version"\s*:\s*"(V[0-9]+)"/ ) {
        $version = $1;
    }

    return $version;
}

sub save_tmp {
    my ( $self ) = @_;
    $self->save( $self->default_working_file );
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

1;
