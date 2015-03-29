package Pcode::App::SideMenu;

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
    $self->widget( $self->build_side_menu );
}

sub build_side_menu {
    my ( $self ) = @_;

    my $prop_box = Gtk2::VBox->new( FALSE, 0 );
    $self->app->prop_box( $prop_box );

    my $prop_box_holder = Gtk2::HBox->new( FALSE, 0 );
    $prop_box_holder->pack_start( $prop_box, FALSE, FALSE, 0 );

    my $vbox = Gtk2::VBox->new( FALSE, 0 );
    my $line_btn = $self->build_button( "Line", 'line', sub { $self->app->mode( 'line' ) } );
    my $arc_btn = $self->build_button( "Arc", 'arc', sub { $self->app->codewindow->parse_code } );
    my $clr_btn = $self->build_button( "Clear", 'clr', sub { $self->app->clear_all } );
    $vbox->pack_start( $line_btn, FALSE, FALSE, 0 );
    $vbox->pack_start( $arc_btn, FALSE, FALSE, 0 );
    $vbox->pack_start( $clr_btn, FALSE, FALSE, 0 );
    $vbox->pack_start( $prop_box_holder, FALSE, FALSE, 0 );

    return $vbox;
}

sub build_button {
    my ( $self, $label_txt, $icon, $handler ) = @_;

    my $box = Gtk2::HBox->new( FALSE, 0 );
    $box->set_border_width( 2 );

    my $image = Gtk2::Image->new_from_file( $self->icon_to_filename( $icon ) );
    my $label = Gtk2::Label->new( $label_txt );

    $box->pack_start( $image, FALSE, FALSE, 0 );
    $box->pack_start( $label, FALSE, FALSE, 0 );

    my $button = Gtk2::Button->new();
    $button->signal_connect( 'clicked' => $handler );

    $button->add( $box );

    return $button;
}

sub icon_to_filename {
    my ( $self, $icon ) = @_;
    return sprintf( '/home/ceade/src/personal/perl/pcode/images/%s.xpm', $icon );
}

1;
