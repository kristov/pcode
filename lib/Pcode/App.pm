package Pcode::App;

use Moose;

use Cairo;
use Gtk2 qw( -init );
use Glib qw( TRUE FALSE );

use Pcode::Point;
use Pcode::CommandList;
use Pcode::Command::Line;
use Pcode::Command::Arc;

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

has 'command_list' => (
    is  => 'rw',
    isa => 'Pcode::CommandList',
    default => sub { Pcode::CommandList->new(); },
    documentation => "List of commands",
);

sub BUILD {
    my ( $self ) = @_;

    my $width = $self->width;
    my $height = $self->height;

    # The graphical environment
    $self->win( Gtk2::Window->new( 'toplevel' ) );
    $self->win->set_default_size( $width, $height );
    $self->win()->signal_connect( key_press_event => sub { $self->handle_keypress( @_ ) } );

    my $hbox = Gtk2::HBox->new( FALSE, 0 );
    my $vbox = Gtk2::VBox->new( FALSE, 0 );

    $self->da( Gtk2::DrawingArea->new );
    #$self->da->size( $width, $height );
    $self->da->signal_connect( expose_event => sub { $self->render( @_ ) } );

    my $side_menu = $self->build_side_menu;

    $hbox->pack_start( $side_menu, FALSE, FALSE, 0 );
    $hbox->pack_start( $self->da, TRUE, TRUE, 0 );
    $vbox->pack_start( $hbox, TRUE, TRUE, 0 );

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

sub build_side_menu {
    my ( $self ) = @_;

    my $prop_box = Gtk2::VBox->new( FALSE, 0 );
    $self->prop_box( $prop_box );

    my $prop_box_holder = Gtk2::HBox->new( FALSE, 0 );
    $prop_box_holder->pack_start( $prop_box, FALSE, FALSE, 0 );

    my $vbox = Gtk2::VBox->new( FALSE, 0 );
    my $line_btn = $self->build_button( "Line", 'line', sub { $self->mode( 'line' ) } );
    my $arc_btn = $self->build_button( "Arc", 'arc', sub { $self->mode( 'arc' ) } );
    my $clr_btn = $self->build_button( "Clear", 'clr', sub { $self->clear_all } );
    $vbox->pack_start( $line_btn, FALSE, FALSE, 0 );
    $vbox->pack_start( $arc_btn, FALSE, FALSE, 0 );
    $vbox->pack_start( $clr_btn, FALSE, FALSE, 0 );
    $vbox->pack_start( $prop_box_holder, FALSE, FALSE, 0 );

    return $vbox;
}

sub clear_all {
    my ( $self ) = @_;
    $self->command_list->clear;
    $self->invalidate;
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

sub motion_notify {
    my ( $self, $widget, $event, $data ) = @_;
    my ( $x, $y ) = ( $event->x, $event->y );

    ( $x, $y ) = $self->translate_from_screen_coords( $x, $y );
    
    $self->detect_point_snap( $x, $y );

    if ( $self->start_point ) {
        $self->mouse_x( $x );
        $self->mouse_y( $y );
    }

    $self->invalidate;
}

sub invalidate {
    my ( $self ) = @_;
    my $update_rect = Gtk2::Gdk::Rectangle->new( 0, 0, $self->da_width, $self->da_height );
    $self->da->window->invalidate_rect( $update_rect, FALSE );
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

    my $table = $self->edit_properties( $command );
    if ( $table ) {
        $self->prop_box->pack_start( $table, FALSE, FALSE, 0 );
    }

    return if !$table;

    $self->prop_box->show_all;
}

sub edit_properties {
    my ( $self, $command ) = @_;

    my @sections;

    if ( $command->can( 'start' ) ) {
        push @sections, {
            header     => 'Start point',
            object     => $command->start,
            properties => $command->start->properties,
        };
    }
    if ( $command->can( 'properties' ) ) {
        push @sections, {
            header     => 'Start point',
            object     => $command,
            properties => $command->properties,
        };
    }
    if ( $command->can( 'end' ) ) {
        push @sections, {
            header     => 'End point',
            object     => $command->end,
            properties => $command->end->properties,
        };
    }

    my $rows = 0;
    for my $section ( @sections ) {
        for my $property ( @{ $section->{properties} } ) {
            $rows++;
        }
    }
    my $table = Gtk2::Table->new( $rows, 2, FALSE );

    my $count = 0;
    for my $section ( @sections ) {
        my $object = $section->{object};
        for my $property ( @{ $section->{properties} } ) {
            my $name = $property->{name};
            my $label = Gtk2::Label->new( $property->{label} || '<unknown>' );
            my $value = $object->$name();
            my $widget;
            if ( $property->{type} eq 'Num' ) {
                $widget = $self->num_widget( $object, $name, $value );
            }
            elsif ( $property->{type} eq 'Bool' ) {
                $widget = $self->bool_widget( $object, $name, $value );
            }
            $table->attach( $label, 0, 1, $count, $count + 1, [ 'fill' ], [ 'fill' ], 0, 0 );
            $table->attach( $widget, 1, 2, $count, $count + 1, [ 'fill' ], [ 'fill' ], 0, 0 );
            $count++;
        }
    }

    return $table;
}

sub num_widget {
    my ( $self, $object, $name, $value ) = @_;

    my $adjustment = Gtk2::Adjustment->new( $value, 0, 1000, 0.01, 1, 0 );
    my $spin = Gtk2::SpinButton->new( $adjustment, 0.5, 2 );

    my $data = { object => $object, name => $name };

    $adjustment->signal_connect( value_changed => sub {
        my ( $widget, $info ) = @_;

        my $value = $widget->get_value();
        my $object = $info->{object};
        my $name = $info->{name};

        my $set_value = $object->$name( $value );
        if ( $set_value != $value ) {
            $widget->set_value( $set_value );
        }
        $self->invalidate;
    }, $data );

    return $spin;
}

sub bool_widget {
    my ( $self, $object, $name, $value ) = @_;

    my $data = { object => $object, name => $name };

    my $button = Gtk2::CheckButton->new();
    $button->set_active( $value ? TRUE : FALSE );
    $button->signal_connect( toggled => sub {
        my ( $widget, $info ) = @_;

        my $value = $widget->get_active();
        my $object = $info->{object};
        my $name = $info->{name};

        $object->$name( $value );
        $self->invalidate;
    }, $data );

    return $button;
}

sub line_mode_click {
    my ( $self, $x, $y, $snap_point ) = @_;

    if ( $self->start_point ) {
        my $end_point = $snap_point || Pcode::Point->new( { X => $x, Y => $y } );

        my $new_line = Pcode::Command::Line->new( {
            start => $self->start_point,
            end   => $end_point,
        } );
        $self->command_list->append( $new_line );
        
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

        $self->command_list->append( Pcode::Command::Arc->new( {
            start  => $self->start_point,
            end    => $end_point,
            radius => $r,
        } ) );

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

    #if ( $self->draw_line ) {
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
            my $parallel = $command->parallel( 40 );
            if ( $parallel ) {
                $parallel->dashed( 1 );
                $parallel->render( $self, $cr );
            }
        }

    }

    my $command_list = $self->command_list;
    my $prev_command;
    my $prev_parallel;
    my $parallel_list = [];

    for my $commanditem ( @{ $command_list->list } ) {
        my $command = $commanditem->command;
        my @parallels = $self->render_command( $cr, $command, $prev_command, $prev_parallel );
        $prev_parallel = $parallels[-1];
        push @{ $parallel_list }, @parallels;
        $prev_command = $command;
    }

    for my $parallel ( @{ $parallel_list } ) {
        $parallel->dashed( 1 );
        $parallel->render( $self, $cr );
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

    my $current_point = Pcode::Point->new( { X => $x, Y => $y } );

    my $command_list = $self->command_list;

    my $found_point;

    for my $commanditem ( @{ $command_list->list } ) {
        my $command = $commanditem->command;

        for my $point ( $command->start, $command->end ) {
            if ( $point->distance( $current_point ) <= 5 ) {
                $point->hover( 1 );
                if ( !$self->hover_point || !$self->hover_point->equal( $point ) ) {
                    $self->invalidate;
                    $self->hover_point( $point );
                }
                $found_point = $point;
            }
            else {
                $point->hover( 0 );
            }
        }
    }

    return $found_point;
}

sub detect_line_snap {
    my ( $self, $x, $y ) = @_;

    my $current_point = Pcode::Point->new( { X => $x, Y => $y } );

    my $command_list = $self->command_list;

    my $found_line;

    for my $commanditem ( @{ $command_list->list } ) {
        my $command = $commanditem->command;
        if ( $command->distance_to_point( $current_point ) <= 5 ) {
            $command->hover( 1 );
            if ( !$self->hover_line || !$self->hover_line->equal( $command ) ) {
                $self->invalidate;
                $self->hover_line( $command );
            }
            $found_line = $command;
        }
        else {
            $command->hover( 0 );
        }
    }

    return $found_line;
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
