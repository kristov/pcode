package Pcode::App::Properties;

use Moose;
use Glib qw( TRUE FALSE );

has 'object' => (
    is  => 'rw',
    isa => 'Object',
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
            header     => 'Start point',
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
        for my $property ( @{ $section->{properties} } ) {
            $rows++;
        }
    }
    my $table = Gtk2::Table->new( $rows, 2, FALSE );

    my $count = 0;
    for my $section ( @sections ) {
        my $obj = $section->{object};
        for my $property ( @{ $section->{properties} } ) {
            my $name = $property->{name};
            my $label = Gtk2::Label->new( $property->{label} || '<unknown>' );
            my $value = $obj->$name();
            my $widget;
            if ( $property->{type} eq 'Num' ) {
                $widget = $self->num_widget( $obj, $name, $value );
            }
            elsif ( $property->{type} eq 'Bool' ) {
                $widget = $self->bool_widget( $obj, $name, $value );
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
        $self->app->invalidate;
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
        $self->app->invalidate;
    }, $data );

    return $button;
}

1;