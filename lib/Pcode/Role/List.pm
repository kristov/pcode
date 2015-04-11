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

sub count {
    my ( $self ) = @_;
    my $list = $self->list;
    return scalar( @{ $list } );
}

sub last {
    my ( $self ) = @_;
    my $list = $self->list;
    return $list->[-1] if @{ $list };
    return;
}

sub first {
    my ( $self ) = @_;
    my $list = $self->list;
    return $list->[0] if @{ $list };
    return;
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
