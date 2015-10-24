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
        [ "Drill",              'drl',  sub { $self->app->mode( 'drl' ) } ],
        [ "Parse code window",  'prs',  sub { $self->app->code_window->parse_code } ],
        [ "Set machine center", 'mce',  sub { $self->app->mode( 'mce' ) } ],
        [ "Set path center",    'pce',  sub { $self->app->mode( 'pce' ) } ],
        [ "Move window",        'mov',  sub { $self->app->mode( 'mov' ) } ],
        [ "Zoom in",            'zin',  sub { $self->app->mode( 'zin' ) } ],
        [ "Zoom out",           'zot',  sub { $self->app->mode( 'zot' ) } ],
        [ "Zoom fit",           'zit',  sub { $self->app->zoom_to_fit } ],
        [ "Generate G-CODE",    'gcd',  sub { $self->app->generate_gcode } ],
        [ "Delete all paths",   'clr',  sub { $self->app->clear_all } ],
        [ "Save",               'sav',  sub { $self->save } ],
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
    return sprintf( '%s/images/%s.xpm', $self->app->install_dir, $icon );
}

sub save {
    my ( $self ) = @_;
    my $file_chooser = Gtk2::FileChooserDialog->new(
        "Save work",
        undef,
        'save',
        'gtk-cancel' => 'cancel',
        'gtk-ok'     => 'ok',
    );
    #$file_chooser->add_filter($filter);

    $file_chooser->set_current_name( "suggeste_this_file.name" );

    my $filename;
    if ( $file_chooser->run eq 'ok' ) {
        $filename = $file_chooser->get_filename;
        $self->app->file( $filename );
        $self->app->save;
    }

    $file_chooser->destroy;
}

1;
