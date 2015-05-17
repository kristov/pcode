package Pcode::App::TopMenu;

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

    my $plugin_menu = Gtk2::Menu->new();
    my @plugins = $self->app->plugins;
    for my $plugin ( @plugins ) {
        my $label = $plugin;
        $label =~ s/^Pcode::Recipe:://;
        my $menu_item = Gtk2::MenuItem->new( $label );
        $menu_item->signal_connect( 'activate' => sub { $self->app->mode( $plugin ) } );
        $plugin_menu->append( $menu_item );
    }

    my $plugin_menu_item = Gtk2::MenuItem->new( "_Plugins" );
    $plugin_menu_item->set_submenu( $plugin_menu );

    my $menu_bar = Gtk2::MenuBar->new();
    $menu_bar->append( $plugin_menu_item );
    $self->widget( $menu_bar );
}

1;
