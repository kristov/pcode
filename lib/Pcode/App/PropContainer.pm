package Pcode::App::PropContainer;

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

sub BUILD {
    my ( $self ) = @_;
    my $prop_box = Gtk2::VBox->new( FALSE, 0 );
    $self->widget( $prop_box );
}

sub show_props {
    my ( $self, $props ) = @_;
    $self->widget->foreach( sub { $self->widget->remove( $_[0] ) } );
    $self->widget->pack_start( $props->widget, FALSE, FALSE, 0 );
    $self->widget->show_all;
}

1;
