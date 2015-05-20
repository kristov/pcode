package Pcode::App::PropContainer;

use Moose;

use Glib qw( TRUE FALSE );

has 'app' => (
    is  => 'rw',
    isa => 'Pcode::App',
    required => 1,
    documentation => 'Invalidate when things change',
);

has 'vbox' => (
    is  => 'rw',
    isa => 'Object',
    documentation => 'Gtk2::VBox',
);

has 'widget' => (
    is  => 'rw',
    isa => 'Object',
    documentation => 'The widget to render',
);

sub BUILD {
    my ( $self ) = @_;
    my $vbox = Gtk2::VBox->new( FALSE, 0 );
    $self->vbox( $vbox );

    my $sw = Gtk2::ScrolledWindow->new( undef, undef );
    $sw->set_shadow_type( 'etched-out' );
    $sw->set_policy( 'automatic', 'automatic' );

    $sw->add_with_viewport( $vbox );

    $self->widget( $sw );
}

sub show_props {
    my ( $self, $props ) = @_;
    $self->vbox->foreach( sub { $self->vbox->remove( $_[0] ) } );
    $self->vbox->pack_start( $props->widget, FALSE, FALSE, 0 );
    $self->vbox->show_all;
}

1;
