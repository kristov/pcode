package Pcode::CommandList;

use Moose;
use Pcode::CommandList::Item;

has 'list' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [ ] },
    documentation => '',
);

sub append {
    my ( $self, $command ) = @_;
    my $commandlistitem = Pcode::CommandList::Item->new( { command => $command } );
    my $list = $self->list;
    push @{ $list }, $commandlistitem;
}

sub clear {
    my ( $self ) = @_;
    my $list = $self->list;
    $list = [];
    $self->list( $list );
}

1;
