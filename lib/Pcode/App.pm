package Pcode::App;

use Moose;

use Cairo;
use Gtk2 qw( -init );
use Glib qw( TRUE FALSE );

use Pcode::Point;
use Pcode::Path;
use Pcode::PathList;
use Pcode::Command::Line;
use Pcode::Command::Arc;
use Pcode::App::Properties;
use Pcode::App::SideMenu;

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
    isa => 'Gtk2::VBox',
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
    default => 0,
    documentation => "Viewing window offset X",
);

has 'y_offset' => (
    is  => 'rw',
    isa => 'Int',
    default => 0,
    documentation => "Viewing window offset Y",
);

has 'zoom' => (
    is  => 'rw',
    isa => 'Num',
    default => 0,
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

sub BUILD {
    my ( $self ) = @_;

    my $width = $self->width;
    my $height = $self->height;

#use Pcode::Snap::Circle;
#use Pcode::Snap::Line;
    my $current_path = Pcode::Path->new();
    $self->current_path( $current_path );
    $self->paths->add( $current_path );
#    $self->current_path->snaps->add( Pcode::Snap::Circle->new( { center => Pcode::Point->new( { X => 100, Y => 100 } ), radius => 200 } ) );
#    $self->current_path->snaps->add( Pcode::Snap::Line->new( { start => Pcode::Point->new( { X => 100, Y => 100 } ), end => Pcode::Point->new( { X => 300, Y => 300 } ) } ) );

    # The graphical environment
    $self->win( Gtk2::Window->new( 'toplevel' ) );
    $self->win->set_default_size( $width, $height );
    $self->win()->signal_connect( key_press_event => sub { $self->handle_keypress( @_ ) } );

    my $hbox = Gtk2::HBox->new( FALSE, 0 );
    my $vbox = Gtk2::VBox->new( FALSE, 0 );

    $self->da( Gtk2::DrawingArea->new );
    #$self->da->size( $width, $height );
    $self->da->signal_connect( expose_event => sub { $self->render( @_ ) } );

    my $side_menu = Pcode::App::SideMenu->new( { app => $self } );
    my $textarea = $self->build_command_area;

    $hbox->pack_start( $side_menu->widget, FALSE, FALSE, 0 );
    $hbox->pack_start( $self->da, TRUE, TRUE, 0 );
    $vbox->pack_start( $hbox, TRUE, TRUE, 0 );
    $vbox->pack_start( $textarea, FALSE, FALSE, 0 );

    $self->da->set_events( [
        'exposure-mask',
        'leave-notify-mask',
        'button-press-mask',
        'pointer-motion-mask',
        'pointer-motion-hint-mask',
    ] );

    $self->da->signal_connect( 'button-press-event' => sub { return $self->button_clicked( @_ ) } );
    $self->da->signal_connect( 'motion-notify-event' => sub { $self->motion_notify( @_ ) } );

    my $color = Gtk2::Gdk::Color->new( 0, 0, 0 );
    $self->da->modify_bg( 'normal', $color );

    $self->win->add( $vbox );

    $self->win->signal_connect( delete_event => sub { exit; } );

    $self->win->show_all;
}

sub build_command_area {
    my ( $self ) = @_;

    my $scroll = Gtk2::ScrolledWindow->new( undef, undef );
    $scroll->set_policy( 'automatic', 'automatic' );

    my $text = Gtk2::TextView->new();
    $self->text( $text );
    my $buffer = $text->get_buffer;

    $scroll->add( $text );
    return $scroll;
}

sub clear_all {
    my ( $self ) = @_;
    $self->current_path->clear;
    $self->invalidate;
}

sub motion_notify {
    my ( $self, $widget, $event, $data ) = @_;
    my ( $x, $y ) = ( $event->x, $event->y );

    ( $x, $y ) = $self->translate_from_screen_coords( $x, $y );
    
    $self->detect_point_snap( $x, $y );

    if ( $self->start_point ) {
        $self->mouse_x( $x );
        $self->mouse_y( $y );
        $self->invalidate;
    }
}

sub invalidate {
    my ( $self ) = @_;
    my $update_rect = Gtk2::Gdk::Rectangle->new( 0, 0, $self->da_width, $self->da_height );
    $self->da->window->invalidate_rect( $update_rect, FALSE );
    $self->update_command_window;
}

sub update_command_window {
    my ( $self ) = @_;

    my $text = $self->text;
    my $buffer = $text->get_buffer;

    my $command_text = $self->current_path->stringify;

    $buffer->set_text( $command_text );
}

sub button_clicked {
    my ( $self, $widget, $event ) = @_;
    my ( $x, $y, $button ) = ( $event->x, $event->y, $event->button );

    ( $x, $y ) = $self->translate_from_screen_coords( $x, $y );

    my $button_nr = $event->button;

    if ( $button_nr == 1 ) {
        return $self->left_button_clicked( $x, $y );
    }
    elsif ( $button_nr == 3 ) {
        return $self->right_button_clicked( $x, $y );
    }
}

sub left_button_clicked {
    my ( $self, $x, $y ) = @_;

    my $snap_point = $self->detect_point_snap( $x, $y );

    my $mode = $self->mode;
    if ( $mode eq 'line' ) {
        $self->line_mode_click( $x, $y, $snap_point );
    }
    elsif ( $mode eq 'arc' ) {
        $self->arc_mode_click( $x, $y, $snap_point );
    }

    #$self->draw_line( 0 );

    return TRUE;
}

sub right_button_clicked {
    my ( $self, $x, $y ) = @_;

    if ( $self->start_point ) {
        $self->start_point( undef );
        $self->invalidate;
    }

    my $snap_point = $self->detect_point_snap( $x, $y );

    if ( $snap_point ) {
        $self->modal_edit_window( $snap_point );
    }
    else {
        my $command = $self->detect_line_snap( $x, $y );
        if ( $command ) {
            $self->modal_edit_window( $command );
            return TRUE;
        }
    }

    return TRUE;
}

sub modal_edit_window {
    my ( $self, $command ) = @_;

    $self->prop_box->foreach( sub { $self->prop_box->remove( $_[0] ) } );

    my $props = Pcode::App::Properties->new( { object => $command, app => $self } );
    my $table = $props->widget;

    if ( $table ) {
        $self->prop_box->pack_start( $table, FALSE, FALSE, 0 );
    }

    return if !$table;

    $self->prop_box->show_all;
}

sub line_mode_click {
    my ( $self, $x, $y, $snap_point ) = @_;

    if ( $self->start_point ) {
        my $end_point = $snap_point || Pcode::Point->new( { X => $x, Y => $y } );

        my $new_line = Pcode::Command::Line->new( {
            start => $self->start_point,
            end   => $end_point,
        } );

        $self->current_path->append_command( $new_line );
        
        $self->start_point( undef );
        $self->invalidate;
    }
    else {
        my $start_point = $snap_point || Pcode::Point->new( { X => $x, Y => $y } );
        $self->start_point( $start_point );
    }
}

sub arc_mode_click {
    my ( $self, $x, $y, $snap_point ) = @_;

    if ( $self->start_point ) {
        my $end_point = $snap_point || Pcode::Point->new( { X => $x, Y => $y } );

        my $r = $self->start_point->distance( $end_point );
        $r = int( $r );

        my $new_arc = Pcode::Command::Arc->new( {
            start  => $self->start_point,
            end    => $end_point,
            radius => $r,
        } );

        $self->current_path->append_command( $new_arc );

        $self->start_point( undef );
        $self->invalidate;
    }
    else {
        my $start_point = $snap_point || Pcode::Point->new( { X => $x, Y => $y } );
        $self->start_point( $start_point );
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

    if ( $self->start_point ) {
        
        my $x = $self->mouse_x;
        my $y = $self->mouse_y;
        my $end = Pcode::Point->new( { X => $x, Y => $y } );

        my $command;
        if ( $self->mode eq 'line' ) {
            $command = $self->temporary_line( $self->start_point, $end );
        }
        elsif ( $self->mode eq 'arc' ) {
            $command = $self->temporary_arc( $self->start_point, $end );
        }

        if ( $command ) {
            $command->render( $self, $cr );
        }

    }

    if ( $self->current_path ) {
        $self->current_path->render( $self, $cr );
    }
}

sub render_command {
    my ( $self, $cr, $command, $prev_command, $prev_parallel ) = @_;
    
    $command->render( $self, $cr );

    my $parallel = $command->parallel( 40 );
    my @parallels;

    if ( $parallel ) {
        if ( $prev_parallel ) {
            if ( $command->can( 'radius' ) && $prev_command->can( 'radius' ) ) {
                my ( $point1, $point2 ) = $parallel->intersection_arc( $prev_parallel );
                if ( $point1 && $point2 ) {
                    my $point;
                    if ( $command->point_within_arc( $point1 ) && $prev_command->point_within_arc( $point1 ) ) {
                        $point = $point1;
                        $prev_parallel->end( $point );
                        $parallel->start( $point );
                        push @parallels, $parallel;
                    }
                    elsif ( $command->point_within_arc( $point2 ) && $prev_command->point_within_arc( $point2 ) ) {
                        $point = $point2;
                        $prev_parallel->end( $point );
                        $parallel->start( $point );
                        push @parallels, $parallel;
                    }
                    else {
                        my $distance1 = $point1->distance( $parallel->start );
                        my $distance2 = $point2->distance( $parallel->start );
                        my $closest = ( $distance1 < $distance2 ) ? $distance1 : $distance2;
                        $point = ( $distance1 < $distance2 ) ? $point1 : $point2;
                        if ( $closest > 80 * 2 ) {
                            my $distance = $prev_parallel->end->distance( $parallel->start );
                            my $radius = $distance / 2;
                            my $new_parallel = Pcode::Command::Arc->new( {
                                start  => $prev_parallel->end,
                                end    => $parallel->start,
                                radius => $radius,
                            } );
                            push @parallels, $new_parallel;
                            push @parallels, $parallel;
                        }
                        else {
                            $prev_parallel->end( $point );
                            $parallel->start( $point );
                            push @parallels, $parallel;
                        }
                    }
                }
                else {
                    my $distance = $prev_parallel->end->distance( $parallel->start );
                    my $radius = $distance / 2;
                    my $new_parallel = Pcode::Command::Arc->new( {
                        start  => $prev_parallel->end,
                        end    => $parallel->start,
                        radius => $radius,
                    } );
                    push @parallels, $new_parallel;
                    push @parallels, $parallel;
                }
            }
            else {
                push @parallels, $parallel;
            }
        }
        else {
            push @parallels, $parallel;
        }
        return @parallels;
    }
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
    my ( $self, $x, $y ) = @_;
    return $self->current_path->detect_point_snap( $self, $x, $y );
}

sub detect_line_snap {
    my ( $self, $x, $y ) = @_;
    return $self->current_path->detect_line_snap( $self, $x, $y );
}

sub translate_to_screen_coords {
    my ( $self, @coords ) = @_;
    # x_offset
    # y_offset
    # zoom
    @coords = map { $_ * 0.5 } @coords;
    return @coords;
}

sub translate_from_screen_coords {
    my ( $self, @coords ) = @_;
    @coords = map { $_ / 0.5 } @coords;
    return @coords;
}

sub render {
    my ( $self, $widget, $event ) = @_;

    my ( $da_width, $da_height ) = $self->da->window->get_size;
    $self->da_width( $da_width );
    $self->da_height( $da_height );

    $self->do_cairo_drawing;
    my $cr = Gtk2::Gdk::Cairo::Context->create( $widget->window );
    $cr->set_source_surface( $self->surface(), 0, 0 );
    $cr->paint;
    return FALSE;
}

sub handle_keypress {
}

sub run {
    my ( $self ) = @_;

    $self->do_cairo_drawing();

    #Glib::Timeout->add( 10, sub { $self->process_timer } );

    Gtk2->main();
}

1;
