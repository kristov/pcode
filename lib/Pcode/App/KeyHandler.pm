package Pcode::App::KeyHandler;

use Moose;

has 'app' => (
    is  => 'rw',
    isa => 'Pcode::App',
    required => 1,
    documentation => 'The app context',
);

has 'dispatch' => (
    is  => 'rw',
    isa => 'HashRef',
    default => sub {
        return {
            DA => {
                escape => sub {
                    my ( $self ) = @_;
                    $self->app->cancel_action;
                },
                backspace => sub {
                    my ( $self ) = @_;
                    $self->app->delete_last_command;
                },
                z => sub {
                    my ( $self ) = @_;
                    $self->app->fit_screen;
                },
            },
            OT => {
                backspace => sub {
                    my ( $self ) = @_;
                    $self->app->delete_selected_object;
                },
            },
        },
    },
    documentation => 'Key press dispatch',
);

sub handle {
    my ( $self, $context, $widget, $event ) = @_;

    my $keyval = $event->keyval();

    my $code2key = {
        65362 => 'up',
        65364 => 'down',
        65361 => 'left',
        65363 => 'right',
        65293 => 'enter',
        65289 => 'tab',
        65307 => 'escape',
        65288 => 'backspace',
        105   => 'i',
        109   => 'm',
        122   => 'z',
    };
    my $keyname = $code2key->{$keyval};

    if ( $keyname ) {
        if ( $self->dispatch->{$context}->{$keyname} ) {
            $self->dispatch->{$context}->{$keyname}->( $self );
            return 1;
        }
    }
    else {
        print "unknown key: $keyval\n";
    }

    return;
}

sub dispatch_keypress {
    my ( $self, $key ) = @_;
}

1;
