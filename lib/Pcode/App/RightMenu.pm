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

sub BUILD {
    my ( $self ) = @_;
    my $vbox = Gtk2::VBox->new( FALSE, 5 );
    $self->widget( $vbox );
}

1;
