package Pcode::App::GcodeWindow;

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

has 'full_text' => (
    is  => 'rw',
    isa => 'Object',
    documentation => 'Text object',
);

has 'test_text' => (
    is  => 'rw',
    isa => 'Object',
    documentation => 'Text object',
);

sub BUILD {
    my ( $self ) = @_;

    my $window = Gtk2::Window->new( 'toplevel' );
    $window->signal_connect( delete_event => \&Gtk2::Widget::hide_on_delete );

    my $full_scroll = Gtk2::ScrolledWindow->new( undef, undef );
    $full_scroll->set_shadow_type( 'etched-out' );
    $full_scroll->set_policy( 'automatic', 'automatic' );
    $full_scroll->set_size_request( 300, 200 );
    $full_scroll->set_border_width( 5 );

    my $test_scroll = Gtk2::ScrolledWindow->new( undef, undef );
    $test_scroll->set_shadow_type( 'etched-out' );
    $test_scroll->set_policy( 'automatic', 'automatic' );
    $test_scroll->set_size_request( 300, 200 );
    $test_scroll->set_border_width( 5 );

    my $full_text = Gtk2::TextView->new();
    $self->full_text( $full_text );

    my $test_text = Gtk2::TextView->new();
    $self->test_text( $test_text );

    $full_scroll->add( $full_text );
    $test_scroll->add( $test_text );

    my $nb = Gtk2::Notebook->new();

    $nb->append_page( $full_scroll, "Full G-code" );
    $nb->append_page( $test_scroll, "Test G-code" );

    $window->add( $nb );

    $self->widget( $window );
}

sub show_gcode {
    my ( $self, $full_gcode, $test_gcode ) = @_;
    $self->show_gcode_widget( $full_gcode, $self->full_text );
    $self->show_gcode_widget( $test_gcode, $self->test_text );
    $self->widget->show_all;
}

sub show_gcode_widget {
    my ( $self, $gcode, $textarea ) = @_;
    my $buffer = $textarea->get_buffer;
    $buffer->set_text( $gcode );
}

sub hide {
    my ( $self ) = @_;
    $self->widget->hide;
}

1;
