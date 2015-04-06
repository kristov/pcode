package Pcode::App::CodeWindow;

use Moose;
use Glib qw( TRUE FALSE );

has 'app' => (
    is  => 'rw',
    isa => 'Pcode::App',
    required => 1,
    documentation => 'Invalidate when things change',
);

has 'widget' => (
    is  => 'rw',
    isa => 'Object',
    documentation => 'The widget to render',
);

has 'text' => (
    is  => 'rw',
    isa => 'Object',
    documentation => 'Text object',
);

sub BUILD {
    my ( $self ) = @_;
    $self->widget( $self->build_code_window );
}

sub build_code_window {
    my ( $self ) = @_;

    my $scroll = Gtk2::ScrolledWindow->new( undef, undef );
    $scroll->set_shadow_type( 'etched-out' );
    $scroll->set_policy( 'automatic', 'automatic' );
    $scroll->set_size_request( 300, 200 );
    $scroll->set_border_width( 5 );

    my $text = Gtk2::TextView->new();
    $self->text( $text );
    my $buffer = $text->get_buffer;

    $scroll->add( $text );

    return $scroll;
}

sub update_from_snaps {
    my ( $self ) = @_;

    my $textarea = $self->text;
    
    my $buffer = $textarea->get_buffer;

    my @lines;
    $self->app->snaps->foreach( sub {
        my ( $snap ) = @_;
        my ( $name, $args ) = @{ $snap->serialize };
        push @lines, "$name(" . join( ",", @{ $args } ) . ")";
    } );

    $buffer->set_text( join( "\n", @lines ) );
    #print join( "\n", @lines ) . "\n";
}

sub parse_code {
    my ( $self ) = @_;
    
    my $textarea = $self->text;
    
    my $buffer = $textarea->get_buffer;
    my $text = $buffer->get_text( $buffer->get_start_iter, $buffer->get_end_iter, 1 );
    
    my $things = $self->parse_text( $text );

    $self->app->snaps->clear;
    for my $thing ( @{ $things } ) {
        my ( $name, $args ) = @{ $thing };
        my $object = $self->app->create_object( 'snap', $name, $args );
        $self->app->add_snap( $object ) if $object;
    }
}

sub parse_text {
    my ( $self, $text ) = @_;

    my $things = [];

    my @lines = split( /\n/, $text );
    for my $line ( @lines ) {
        my $command_def = $self->parse_line( $line );
        push @{ $things }, $command_def if $command_def;
    }

    return $things;
}

sub parse_line {
    my ( $self, $line ) = @_;
    my $thing;
    if ( $line =~ /^([a-z]+)\s*\(([^\)]+)\)/ ) {
        my ( $command, $argspec ) = ( $1, $2 );
        my $args = $self->parse_argspec( $argspec );
        $thing = [ $command, $args ] if @{ $args };
    }
    return $thing ? $thing : ();
}

sub parse_argspec {
    my ( $self, $argspec ) = @_;
    my @parts = split( /\s*,\s*/, $argspec );
    return @parts ? \@parts : ();
}

1;
