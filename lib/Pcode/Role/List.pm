package Pcode::Role::List;

use Moose::Role;

has 'list' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [ ] },
    documentation => '',
);

sub add {
    my ( $self, $thing ) = @_;
    $self->append( $thing );
}

sub append {
    my ( $self, $thing ) = @_;
    my $list = $self->list;
    push @{ $list }, $thing;
}

sub clear {
    my ( $self ) = @_;
    my $list = $self->list;
    $list = [];
    $self->list( $list );
}

sub pop {
    my ( $self ) = @_;
    my $list = $self->list;
    my $discarded = pop( @{ $list } );
    $self->list( $list );
}

sub foreach {
    my ( $self, $code ) = @_;
    my $list = $self->list;
    my $last;
    for my $item ( @{ $list } ) {
        $code->( $item, $last );
        $last = $item;
    }
    return $last;
}

1;
