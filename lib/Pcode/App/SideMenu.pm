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

    my $buttons = [
        [ "Draw line",          'line', sub { $self->app->mode( 'line' ) } ],
        [ "Draw arc",           'arc',  sub { $self->app->mode( 'arc' ) } ],
        [ "Parse code window",  'prs',  sub { $self->app->code_window->parse_code } ],
        [ "Set machine center", 'mce',  sub { } ],
        [ "Set path center",    'pce',  sub { } ],
        [ "Move window",        'mov',  sub { } ],
        [ "Zoom in",            'zin',  sub { $self->app->zoom_in } ],
        [ "Zoom out",           'zot',  sub { $self->app->zoom_out } ],
        [ "Delete all paths",   'clr',  sub { $self->app->clear_all } ],
    ];

    my $vbox = Gtk2::VBox->new( FALSE, 0 );
    for my $def ( @{ $buttons } ) {
        my ( $label, $icon, $handler ) = @{ $def };
        my $btn = $self->build_button( $label, $icon, $handler );
        $vbox->pack_start( $btn, FALSE, FALSE, 0 );
    }

    $self->widget( $vbox );
}

sub build_button {
    my ( $self, $label_txt, $icon, $handler ) = @_;

    my $box = Gtk2::HBox->new( FALSE, 0 );
    $box->set_border_width( 2 );

    my $image = Gtk2::Image->new_from_file( $self->icon_to_filename( $icon ) );
    #my $label = Gtk2::Label->new( $label_txt );
    my $toolt = Gtk2::Tooltips->new();

    $box->pack_start( $image, FALSE, FALSE, 0 );
    #$box->pack_start( $label, FALSE, FALSE, 0 );

    my $button = Gtk2::Button->new();
    $button->signal_connect( 'clicked' => $handler );

    $toolt->set_tip( $button, $label_txt );

    $button->add( $box );

    return $button;
}

sub icon_to_filename {
    my ( $self, $icon ) = @_;
    return sprintf( '/home/ceade/src/personal/perl/pcode/images/%s.xpm', $icon );
}

1;
