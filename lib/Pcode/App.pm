package Pcode::App;

use Moose;

use Cairo;
use Gtk2 qw( -init );
use Glib qw( TRUE FALSE );

use Pcode::Point;
use Pcode::Path;
use Pcode::PathList;
use Pcode::SnapList;
use Pcode::Command::Line;
use Pcode::Command::Arc;
use Pcode::Snap::Circle;
use Pcode::Snap::Line;
use Pcode::Snap::Point;
use Pcode::App::Properties;
use Pcode::App::SideMenu;
use Pcode::App::ObjectTree;
use Pcode::App::File::Native;
use Pcode::App::KeyHandler;
use Pcode::App::RightMenu;
use Pcode::App::CodeWindow;
use Pcode::App::PropContainer;
use Pcode::App::GcodeWindow;
use Pcode::App::TopMenu;

use Module::Pluggable search_path => [ 'Pcode::Recipe' ], require => 1;

has 'win' => (
    is  => 'rw',
    isa => 'Gtk2::Window',
    documentation => "GTK window",
);

has 'da' => (
    is  => 'rw',
    isa => 'Gtk2::DrawingArea',
    documentation => "GTK drawing area",
);

has 'prop_box' => (
    is  => 'rw',
    isa => 'Pcode::App::PropContainer',
    documentation => "Generate properties edit in here",
);

has 'surface' => (
    is  => 'rw',
    isa => 'Cairo::ImageSurface',
    documentation => "Cairo surface we are drawing to",
);

has 'text' => (
    is  => 'rw',
    isa => 'Gtk2::TextView',
    documentation => "Command window",
);

has 'width' => (
    is  => 'rw',
    isa => 'Int',
    default => 1024,
    documentation => "Window width",
);

has 'height' => (
    is  => 'rw',
    isa => 'Int',
    default => 700,
    documentation => "Window height",
);

has 'da_width' => (
    is  => 'rw',
    isa => 'Int',
    default => 0,
    documentation => "Drawing Area width",
);

has 'da_height' => (
    is  => 'rw',
    isa => 'Int',
    default => 0,
    documentation => "Drawing Area height",
);

has 'x_offset' => (
    is  => 'rw',
    isa => 'Int',
    default => 10,
    documentation => "Viewing window offset X",
);

has 'y_offset' => (
    is  => 'rw',
    isa => 'Int',
    default => 10,
    documentation => "Viewing window offset Y",
);

has 'zoom' => (
    is  => 'rw',
    isa => 'Num',
    default => 18,
    documentation => "Viewing window zoom",
);

has 'draw_line' => (
    is  => 'rw',
    isa => 'Int',
    documentation => "",
);

has 'mouse_x' => (
    is  => 'rw',
    isa => 'Int',
    default => 0,
    documentation => "",
);

has 'mouse_y' => (
    is  => 'rw',
    isa => 'Int',
    default => 0,
    documentation => "",
);

has 'mode' => (
    is  => 'rw',
    isa => 'Str',
    default => 'line',
    documentation => "Drawing mode",
);

has 'hover_point' => (
    is  => 'rw',
    isa => 'Maybe[Pcode::Point]',
    documentation => "The currently hovered point",
);

has 'hover_line' => (
    is  => 'rw',
    isa => 'Maybe[Object]',
    documentation => "The currently hovered line",
);

has 'start_point' => (
    is  => 'rw',
    isa => 'Maybe[Pcode::Point]',
    documentation => "Current working point",
);

has 'snaps' => (
    is  => 'rw',
    isa => 'Pcode::SnapList',
    default => sub { Pcode::SnapList->new(); },
    documentation => "The snap list",
);

has 'current_path' => (
    is  => 'rw',
    isa => 'Pcode::Path',
    documentation => "Working path",
);

has 'paths' => (
    is  => 'rw',
    isa => 'Pcode::PathList',
    default => sub { Pcode::PathList->new(); },
    documentation => "List of paths",
);

has 'object_tree' => (
    is  => 'rw',
    isa => 'Pcode::App::ObjectTree',
    documentation => "Object tree view",
);

has 'code_window' => (
    is  => 'rw',
    isa => 'Pcode::App::CodeWindow',
    documentation => "The code editing area",
);

has 'gcode_window' => (
    is  => 'rw',
    isa => 'Pcode::App::GcodeWindow',
    documentation => "The code editing area",
);

has 'state' => (
    is  => 'rw',
    isa => 'Pcode::App::File::Native',
    documentation => 'Save app state in a file',
);

has 'file' => (
    is  => 'rw',
    isa => 'Str',
    documentation => 'Working file',
);

has 'keyhandler' => (
    is  => 'rw',
    isa => 'Pcode::App::KeyHandler',
    documentation => "The key press handler",
);

has 'path_center' => (
    is  => 'rw',
    isa => 'Pcode::Point',
    default => sub { Pcode::Point->new( { X => 0, Y => 0 } ) },
    documentation => "The location of the path center",
);

has 'machine_center' => (
    is  => 'rw',
    isa => 'Pcode::Point',
    default => sub { Pcode::Point->new( { X => 0, Y => 0 } ) },
    documentation => "The location of the machine center",
);

has 'install_dir' => (
    is  => 'ro',
    isa => 'Str',
    required => 1,
    documentation => "Where to find this code",
);

sub BUILD {
    my ( $self ) = @_;
    $self->load_file;
    $self->build_gui;
    $self->update_object_tree;
    $self->update_code_window;
}

sub build_gui {    
    my ( $self ) = @_;

    $self->keyhandler( Pcode::App::KeyHandler->new( { app => $self } ) );

    # The graphical environment
    $self->win( Gtk2::Window->new( 'toplevel' ) );
    $self->win->set_default_size( $self->width, $self->height );

    my $hbox = Gtk2::HBox->new( FALSE, 0 );
    my $vbox = Gtk2::VBox->new( FALSE, 0 );

    $self->da( Gtk2::DrawingArea->new );
    $self->da->signal_connect( expose_event => sub { $self->render( @_ ) } );

    my $left_menu  = Pcode::App::SideMenu->new( { app => $self } );

    my $right_menu = Pcode::App::RightMenu->new( { app => $self } );

    my $code_window = Pcode::App::CodeWindow->new( { app => $self } );
    $self->code_window( $code_window );

    my $object_tree = Pcode::App::ObjectTree->new( { app => $self } );
    $self->object_tree( $object_tree );

    my $prop_box = Pcode::App::PropContainer->new( { app => $self } );
    $self->prop_box( $prop_box );

    my $gcode_window = Pcode::App::GcodeWindow->new( { app => $self } );
    $self->gcode_window( $gcode_window );

    my $top_menu = Pcode::App::TopMenu->new( { app => $self } );

    $right_menu->add( {
        object_tree => $object_tree,
        code_window => $code_window,
        prop_box    => $prop_box,
    } );

    $hbox->pack_start( $left_menu->widget, FALSE, FALSE, 0 );
    $hbox->pack_start( $self->da, TRUE, TRUE, 0 );
    $hbox->pack_end( $right_menu->widget, FALSE, FALSE, 0 );

    $vbox->pack_start( $top_menu->widget, FALSE, FALSE, 0 );
    $vbox->pack_start( $hbox, TRUE, TRUE, 0 );

    $self->da->set_events( [
        'key-press-mask',
        'exposure-mask',
        'leave-notify-mask',
        'button-press-mask',
        'pointer-motion-mask',
        'pointer-motion-hint-mask',
    ] );

    $self->da->signal_connect( 'button-press-event' => sub { return $self->button_clicked( @_ ) } );
    $self->da->signal_connect( 'motion-notify-event' => sub { $self->motion_notify( @_ ) } );
    $self->da->signal_connect( 'key-press-event' => sub { $self->keyhandler->handle( @_ ) } );
    $self->da->can_focus( TRUE );
    $self->da->grab_focus;

    my $color = Gtk2::Gdk::Color->new( 0, 0, 0 );
    $self->da->modify_bg( 'normal', $color );

    $self->win->add( $vbox );

    $self->win->signal_connect( delete_event => sub { exit; } );

    $self->win->show_all;
}

sub load_file {
    my ( $self ) = @_;

    $self->state( Pcode::App::File::Native->new( { app => $self } ) );

    if ( $self->file ) {
        $self->state->load( $self->file );
    }
    elsif ( $self->state->working_file_exists ) {
        $self->state->load_working_file;
    }
    else {
        my $current_path = $self->paths->new_path;
        $self->current_path( $current_path );
    }
}

sub new_empty_path {
    my ( $self ) = @_;
    return $self->current_path if $self->current_path->nr_commands == 0;
    
    my $current_path = $self->paths->new_path;
    $self->current_path( $current_path );

    return $current_path;
}

sub cancel_action {
    my ( $self ) = @_;
    if ( $self->start_point ) {
        $self->start_point( undef );
        $self->invalidate;
    }
}

sub delete_last_command {
    my ( $self ) = @_;
    $self->current_path->delete_last;
    # Wrong, always assumes the current_path is the last
    if ( $self->current_path->nr_commands == 0 ) {
        if ( $self->paths->nr_paths > 1 ) {
            my $prev_path = $self->paths->delete_last_path;
            $self->current_path( $prev_path );
        }
    }
    $self->state_change;
}

sub clear_all {
    my ( $self ) = @_;
    $self->current_path->clear;
    $self->state_change;
}

sub create_object {
    my ( $self, $context, $name, $args ) = @_;
    my $class = sprintf( 'Pcode::%s::%s', ucfirst( $context ), ucfirst( $name ) );
    return eval { $class->deserialize( @$args ) };
}

sub add_snap {
    my ( $self, $object ) = @_;
    $self->snaps->add_snap( $object );
    $self->state_change;
}

sub update_object_tree {
    my ( $self ) = @_;
    $self->object_tree->build_tree;
}

sub update_code_window {
    my ( $self ) = @_;
    $self->code_window->update_from_snaps;
}

sub add_command {
    my ( $self, $object ) = @_;
    $self->current_path->append_command( $object );
    $self->state_change;
}

sub motion_notify {
    my ( $self, $widget, $event, $data ) = @_;
    my ( $x, $y ) = ( $event->x, $event->y );

    if ( !$self->da->has_focus ) {
        $self->da->grab_focus;
    }

    my ( $point ) = $self->translate_from_screen_coords( Pcode::Point->new( { X => $x, Y => $y } ) );
    $self->detect_point_snap( $point );

    if ( $self->start_point ) {
        $self->mouse_x( $x );
        $self->mouse_y( $y );
        $self->invalidate;
    }
}

sub state_change {
    my ( $self ) = @_;
    $self->state->save_tmp;
    $self->update_object_tree;
    $self->invalidate;
}

sub save {
    my ( $self ) = @_;
    $self->state->save( $self->file );
}

sub invalidate {
    my ( $self ) = @_;
    my $update_rect = Gtk2::Gdk::Rectangle->new( 0, 0, $self->da_width, $self->da_height );
    $self->da->window->invalidate_rect( $update_rect, FALSE );
}

sub button_clicked {
    my ( $self, $widget, $event ) = @_;
    my ( $x, $y, $button ) = ( $event->x, $event->y, $event->button );

    my ( $point ) = $self->translate_from_screen_coords( Pcode::Point->new( { X => $x, Y => $y } ) );

    my $button_nr = $event->button;

    if ( $button_nr == 1 ) {
        return $self->left_button_clicked( $point );
    }
    elsif ( $button_nr == 3 ) {
        return $self->right_button_clicked( $point );
    }
}

sub left_button_clicked {
    my ( $self, $point ) = @_;

    my $snap_point = $self->detect_point_snap( $point );

    my $mode = $self->mode;
    if ( $mode eq 'line' ) {
        $self->line_mode_click( $point, $snap_point );
    }
    elsif ( $mode eq 'arc' ) {
        $self->arc_mode_click( $point, $snap_point );
    }
    elsif ( $mode eq 'mov' ) {
        $self->mov_mode_click( $point, $snap_point );
    }
    elsif ( $mode eq 'mce' ) {
        $self->mce_mode_click( $point, $snap_point );
    }
    elsif ( $mode eq 'pce' ) {
        $self->pce_mode_click( $point, $snap_point );
    }
    elsif ( $mode ) {
        $self->plugin_click( $mode, $point, $snap_point );
    }

    #$self->draw_line( 0 );

    return TRUE;
}

sub right_button_clicked {
    my ( $self, $point ) = @_;

    if ( $self->start_point ) {
        $self->start_point( undef );
        $self->invalidate;
    }

    my $snap_point = $self->detect_point_snap( $point );

    if ( $snap_point ) {
        $self->modal_edit_window( $snap_point );
    }
    else {
        my $command = $self->detect_line_snap( $point );
        if ( $command ) {
            $self->modal_edit_window( $command );
            return TRUE;
        }
    }

    return TRUE;
}

sub line_mode_click {
    my ( $self, $point, $snap_point ) = @_;

    if ( $self->start_point ) {
        my $end_point = $snap_point || $point;

        my $new_line = Pcode::Command::Line->new( {
            start => $self->start_point,
            end   => $end_point,
        } );

        $self->add_new_command_to_path( $new_line );
    }
    else {
        my $start_point = $snap_point || $point;
        $self->start_point( $start_point );
    }
}

sub arc_mode_click {
    my ( $self, $point, $snap_point ) = @_;

    if ( $self->start_point ) {
        my $end_point = $snap_point || $point;

        my $r = $self->start_point->distance( $end_point );
        $r = int( $r );

        my $new_arc = Pcode::Command::Arc->new( {
            start  => $self->start_point,
            end    => $end_point,
            radius => $r,
        } );

        $self->add_new_command_to_path( $new_arc );
    }
    else {
        my $start_point = $snap_point || $point;
        $self->start_point( $start_point );
    }
}

sub mov_mode_click {
    my ( $self, $point, $snap_point ) = @_;

    my ( $screen ) = $self->translate_to_screen_coords( $point );
    my ( $dw, $dh ) = ( $self->da_width, $self->da_height );

    my $x = $screen->X;
    my $y = $dh - $screen->Y;
    ( $x, $y ) = $self->scale_from_screen( $x, $y );

    $self->x_offset( int( $x ) );
    $self->y_offset( int( $y ) );

    $self->invalidate;
}

sub mce_mode_click {
    my ( $self, $point, $snap_point ) = @_;
    $self->machine_center( $snap_point || $point );
    $self->state_change;
}

sub pce_mode_click {
    my ( $self, $point, $snap_point ) = @_;

    $point = $snap_point if $snap_point;

    my ( $x, $y ) = ( $point->X, $point->Y );
    my $diff_x = 0 - $x;
    my $diff_y = 0 - $y;

    $self->translate_everything( $diff_x, $diff_y );

    $self->state_change;
}

sub translate_everything {
    my ( $self, $x, $y ) = @_;
    $self->snaps->translate( $x, $y );
    $self->paths->translate( $x, $y );
}

sub object_selected {
    my ( $self, $object, $parent_object ) = @_;

    if ( $object ) {
        if ( $parent_object ) {
            $self->current_path->select( $object );
            $self->modal_edit_window( $object );
            $self->invalidate;
        }
        else {
            $self->modal_edit_window( $object );
            $self->current_path( $object );
            $self->invalidate;
        }
    }
}

sub plugin_click {
    my ( $self, $plugin_class, $point, $snap_point ) = @_;

    $point = $snap_point if $snap_point;

    my $object = $plugin_class->new();
    if ( $object->can( 'X' ) && $object->can( 'Y' ) ) {
        $object->X( $point->X );
        $object->Y( $point->Y );
    }

    my $props = Pcode::App::Properties->new( { object => $object, app => $self } );
    return if !$props;

    if ( $props ) {
        $self->prop_box->show_props( $props );
    }

    $object->create( $self );
}

sub modal_edit_window {
    my ( $self, $command ) = @_;

    my $props = Pcode::App::Properties->new( { object => $command, app => $self } );
    return if !$props;

    if ( $props ) {
        $self->prop_box->show_props( $props );
    }
}

sub add_new_command_to_path {
    my ( $self, $new_command ) = @_;

    if ( $self->current_path->last_command ) {
        if ( !$self->current_path->last_command->end->equal( $self->start_point ) ) {
            my $new_path = $self->paths->new_path;
            $self->name_path( $new_path );
            $self->current_path( $new_path );
        }
    }

    $self->current_path->append_command( $new_command );
    $self->start_point( undef );
    $self->state_change;
}

sub name_path {
    my ( $self, $new_path ) = @_;
    my @numbers;
    $self->paths->foreach( sub {
        my ( $path ) = @_;
        if ( $path->name && $path->name =~ /\s([0-9]+)$/ ) {
            push @numbers, $1;
        }
    } );
    if ( @numbers ) {
        my @sorted = sort { $b <=> $a } @numbers;
        my $number = $sorted[0];
        $number++;
        $new_path->name( "Path $number" );
    }
    else {
        $new_path->name( "Path 0" );
    }
}

sub create_surface {
    my ( $self ) = @_;
    my $surface = Cairo::ImageSurface->create( 'argb32', $self->da_width, $self->da_height );
    $self->surface( $surface );
}

sub do_cairo_drawing {
    my ( $self ) = @_;

    $self->create_surface();

    my $surface = $self->surface();
    my $cr = Cairo::Context->create( $surface );
    my $mode = $self->mode;

    if ( $self->start_point ) {
        
        my $x = $self->mouse_x;
        my $y = $self->mouse_y;
        my ( $end ) = $self->translate_from_screen_coords( Pcode::Point->new( { X => $x, Y => $y } ) );

        my $command;
        if ( $mode eq 'line' ) {
            $command = $self->temporary_line( $self->start_point, $end );
        }
        elsif ( $mode eq 'arc' ) {
            $command = $self->temporary_arc( $self->start_point, $end );
        }

        if ( $command ) {
            $command->render( $self, $cr );
        }

    }

    if ( $self->path_center ) {
        $self->render_crosshair( $cr, $self->path_center, [ 0, 1, 0 ] );
    }

    if ( $self->machine_center ) {
        $self->render_crosshair( $cr, $self->machine_center, [ 0, 1, 1 ] );
    }

    if ( $self->snaps ) {
        $self->snaps->render( $self, $cr );
    }

    if ( $self->current_path ) {
        $self->current_path->render( $self, $cr );
    }
}

sub render_crosshair {
    my ( $self, $cr, $point, $color ) = @_;
    $cr->save;

    ( $point ) = $self->translate_to_screen_coords( $point );

    my $x = $point->X;
    my $y = $point->Y;

    my $x1 = $x - 100;
    my $x2 = $x + 100;

    my $y1 = $y - 100;
    my $y2 = $y + 100;

    $cr->set_line_width( 1 );
    $cr->set_source_rgb( @{ $color } );

    $cr->move_to( $x1, $y );
    $cr->line_to( $x2, $y );
    $cr->stroke();

    $cr->move_to( $x, $y1 );
    $cr->line_to( $x, $y2 );
    $cr->stroke();

    $cr->restore;
}

sub temporary_line {
    my ( $self, $start, $end ) = @_;
    return Pcode::Command::Line->new( { start => $start, end => $end } );
}

sub temporary_arc {
    my ( $self, $start, $end ) = @_;
    my $r = $start->distance( $end );
    $r = int( $r );
    return Pcode::Command::Arc->new( { start => $start, end => $end, radius => $r } );
}

sub detect_point_snap {
    my ( $self, $current_point ) = @_;

    my $zoom = $self->zoom;
    my $res = 0.2;

    my $point = $self->current_path->detect_point_snap( $self, $current_point, $res );
    if ( !$point ) {
        $point = $self->snaps->detect_point_snap( $self, $current_point, $res );
    }
    return $point;
}

sub detect_line_snap {
    my ( $self, $point ) = @_;
    return $self->current_path->detect_line_snap( $self, $point );
}

sub zoom_in {
    my ( $self ) = @_;
    my $zoom = $self->zoom;
    $zoom = $zoom + 0.1;
    $self->zoom( $zoom );
    $self->state_change;
}

sub zoom_out {
    my ( $self ) = @_;
    my $zoom = $self->zoom;
    $zoom = $zoom - 0.1;
    $self->zoom( $zoom );
    $self->state_change;
}

sub scale_to_screen {
    my ( $self, @numbers ) = @_;
    my $zoom = $self->zoom;
    @numbers = map { $_ * $zoom } @numbers;
    return @numbers;
}

sub scale_from_screen {
    my ( $self, @numbers ) = @_;
    my $zoom = $self->zoom;
    @numbers = map { $_ / $zoom } @numbers;
    return @numbers;
}

sub translate_to_screen_coords {
    my ( $self, @points ) = @_;

    my @new_points;
    my $da_height = $self->da_height;

    for my $point ( @points ) {
        my ( $x, $y ) = ( $point->X, $point->Y );
        $x = $x + $self->x_offset;
        $y = $y + $self->y_offset;
        ( $x, $y ) = $self->scale_to_screen( $x, $y );
        $y = $da_height - $y;
        push @new_points, Pcode::Point->new( { X => $x, Y => $y } );
    }
    return @new_points;
}

sub translate_from_screen_coords {
    my ( $self, @points ) = @_;
    
    my @new_points;
    my $da_height = $self->da_height;

    for my $point ( @points ) {
        my ( $x, $y ) = ( $point->X, $point->Y );
        $y = $da_height - $y;
        ( $x, $y ) = $self->scale_from_screen( $x, $y );
        $x = $x - $self->x_offset;
        $y = $y - $self->y_offset;
        push @new_points, Pcode::Point->new( { X => $x, Y => $y } );
    }
    return @new_points;
}

sub render {
    my ( $self, $widget, $event ) = @_;

    my ( $da_width, $da_height ) = $self->da->window->get_size;

    $self->da_width( $da_width );
    $self->da_height( $da_height );

    my ( $width, $height ) = $self->win->get_size;
    $self->width( $width );
    $self->height( $height );

    $self->do_cairo_drawing;
    my $cr = Gtk2::Gdk::Cairo::Context->create( $widget->window );
    $cr->set_source_surface( $self->surface(), 0, 0 );
    $cr->paint;
    return FALSE;
}

sub generate_gcode {
    my ( $self ) = @_;
    my ( $full_gcode, $test_gcode ) = $self->paths->generate_gcode( $self->machine_center );
    $self->gcode_window->show_gcode( $full_gcode, $test_gcode );
}

sub run {
    my ( $self ) = @_;

    $self->do_cairo_drawing();

    #Glib::Timeout->add( 10, sub { $self->process_timer } );

    Gtk2->main();
}

1;
