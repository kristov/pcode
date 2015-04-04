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
    default => sub { {
        escape => sub {
            my ( $self ) = @_;
            $self->app->cancel_action;
        },
        backspace => sub {
            my ( $self ) = @_;
            $self->app->delete_last_command;
        },
    } },
    documentation => 'Key press dispatch',
);

sub handle {
    my ( $self, $widget, $event ) = @_;

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
    };
    my $keyname = $code2key->{$keyval};

    if ( $keyname ) {
        if ( $self->dispatch->{$keyname} ) {
            $self->dispatch->{$keyname}->( $self );
            return 1;
        }
    }
    else {
        #print "unknown key: $keyval\n";
    }

    return;
}

sub dispatch_keypress {
    my ( $self, $key ) = @_;
}

1;
