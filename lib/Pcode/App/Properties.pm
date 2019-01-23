package Pcode::App::Properties;

use Moose;
use Glib qw( TRUE FALSE );

has 'object' => (
    is  => 'rw',
    isa => 'Any',
    required => 1,
    documentation => 'The thing to edit properties for',
);

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
    $self->widget( $self->edit_properties );
}

sub title {
    my ( $self ) = @_;
    return ref $self->object;
}

sub edit_properties {
    my ( $self ) = @_;

    my $object = $self->object;

    my @sections;

    if ( $object->can( 'start' ) ) {
        push @sections, {
            header     => 'Start point',
            object     => $object->start,
            properties => $object->start->properties,
        };
    }
    if ( $object->can( 'properties' ) ) {
        push @sections, {
            header     => 'Properties',
            object     => $object,
            properties => $object->properties,
        };
    }
    if ( $object->can( 'end' ) ) {
        push @sections, {
            header     => 'End point',
            object     => $object->end,
            properties => $object->end->properties,
        };
    }

    my $rows = 0;
    for my $section ( @sections ) {
        $rows++;
        for my $property ( @{ $section->{properties} } ) {
            $rows++;
        }
    }
    my $table = Gtk2::Table->new( $rows, 2, FALSE );

    my $count = 0;
    for my $section ( @sections ) {

        my $header = $section->{header};
        my $header_label = Gtk2::Label->new( $header || '<unknown>' );
        $table->attach( $header_label, 0, 2, $count, $count + 1, [ 'fill' ], [ 'fill' ], 5, 5 );
        $count++;

        my $obj = $section->{object};
        for my $property ( @{ $section->{properties} } ) {

            my $name = $property->{name};
            my $label = Gtk2::Label->new( $property->{label} || '<unknown>' );
            my $value = $obj->$name();

            my $widget;
            if ( $property->{type} eq 'Int' ) {
                $widget = $self->int_widget( $obj, $name, $value, $property->{hook} );
            }
            if ( $property->{type} eq 'Num' ) {
                $widget = $self->num_widget( $obj, $name, $value, $property->{hook} );
            }
            elsif ( $property->{type} eq 'Bool' ) {
                $widget = $self->bool_widget( $obj, $name, $value, $property->{hook} );
            }
            elsif ( $property->{type} eq 'Str' ) {
                $widget = $self->string_widget( $obj, $name, $value, $property->{hook} );
            }
            elsif ( $property->{type} eq 'File' ) {
                $widget = $self->file_widget( $obj, $name, $value, $property->{hook} );
            }
            $table->attach( $label, 0, 1, $count, $count + 1, [ 'fill' ], [ 'fill' ], 5, 5 );
            $table->attach( $widget, 1, 2, $count, $count + 1, [ 'fill' ], [ 'fill' ], 5, 5 );
            $count++;
        }
    }

    return $table;
}

sub int_widget {
    my ( $self, $object, $name, $value, $hook ) = @_;

    my $adjustment = Gtk2::Adjustment->new( $value, 0, 1000, 1, 1, 0 );
    my $spin = Gtk2::SpinButton->new( $adjustment, 1, 2 );

    my $data = { object => $object, name => $name, hook => $hook };

    $adjustment->signal_connect( value_changed => sub {
        my ( $widget, $info ) = @_;

        my $value = $widget->get_value();
        my $object = $info->{object};
        my $name = $info->{name};

        my $set_value = $object->$name( $value );
        if ( $set_value != $value ) {
            $widget->set_value( $set_value );
        }
        if ( $info->{hook} ) {
            $info->{hook}->( $object );
        }
        $self->app->state_change;
    }, $data );

    return $spin;
}

sub num_widget {
    my ( $self, $object, $name, $value, $hook ) = @_;

    my $adjustment = Gtk2::Adjustment->new( $value, 0, 1000, 0.01, 1, 0 );
    my $spin = Gtk2::SpinButton->new( $adjustment, 0.5, 2 );

    my $data = { object => $object, name => $name, hook => $hook };

    $adjustment->signal_connect( value_changed => sub {
        my ( $widget, $info ) = @_;

        my $value = $widget->get_value();
        my $object = $info->{object};
        my $name = $info->{name};

        my $set_value = $object->$name( $value );
        if ( $set_value != $value ) {
            $widget->set_value( $set_value );
        }
        if ( $info->{hook} ) {
            $info->{hook}->( $object );
        }
        $self->app->state_change;
    }, $data );

    return $spin;
}

sub bool_widget {
    my ( $self, $object, $name, $value, $hook ) = @_;

    my $data = { object => $object, name => $name, hook => $hook };

    my $button = Gtk2::CheckButton->new();
    $button->set_active( $value ? TRUE : FALSE );
    $button->signal_connect( toggled => sub {
        my ( $widget, $info ) = @_;

        my $value = $widget->get_active();
        my $object = $info->{object};
        my $name = $info->{name};

        $object->$name( $value );
        if ( $info->{hook} ) {
            $info->{hook}->( $object );
        }
        $self->app->state_change;
    }, $data );

    return $button;
}

sub string_widget {
    my ( $self, $object, $name, $value, $hook ) = @_;

    my $data = { object => $object, name => $name, hook => $hook };

    my $entry = Gtk2::Entry->new();
    $entry->set_text( $value ) if defined $value;
    $entry->signal_connect( changed => sub {
        my ( $widget, $info ) = @_;

        my $value = $widget->get_text();
        my $object = $info->{object};
        my $name = $info->{name};

        $object->$name( $value );
        if ( $info->{hook} ) {
            $info->{hook}->( $object );
        }
        $self->app->state_change;
    }, $data );

    return $entry;
}

sub file_widget {
    my ( $self, $object, $name, $value, $hook ) = @_;

    my $data = { object => $object, name => $name, hook => $hook };

    my $open = Gtk2::Button->new( '_Open' );

    $open->signal_connect('clicked' => sub {
        my ( $widget, $info ) = @_;

        my $file_chooser = Gtk2::FileChooserDialog->new( 
            'Pick a file',
            undef,
            'open',
            'gtk-cancel' => 'cancel',
            'gtk-ok'     => 'ok'
        );

        my $object = $info->{object};
        my $name = $info->{name};
        my $value;

        if ( $file_chooser->run eq 'ok' ) {
            $value = $file_chooser->get_filename;
        }
        $file_chooser->destroy;

        $object->$name( $value );
        if ( $info->{hook} ) {
            $info->{hook}->( $object );
        }
        $self->app->state_change;
    }, $data );

    return $open;
}

1;
