package Pcode::App::RightMenu;

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

has 'top_pane' => (
    is  => 'rw',
    isa => 'Gtk2::VPaned',
    documentation => '',
);

has 'bottom_pane' => (
    is  => 'rw',
    isa => 'Gtk2::VPaned',
    documentation => '',
);

sub add {
    my ( $self, $things ) = @_;
    $self->top_pane->add1( $things->{object_tree}->widget );
    $self->bottom_pane->add1( $things->{code_window}->widget );
    $self->bottom_pane->add2( $things->{prop_box}->widget );
}

sub BUILD {
    my ( $self ) = @_;
    $self->top_pane( Gtk2::VPaned->new() );
    $self->bottom_pane( Gtk2::VPaned->new() );
    $self->top_pane->add2( $self->bottom_pane );
    $self->widget( $self->top_pane );
}

1;
