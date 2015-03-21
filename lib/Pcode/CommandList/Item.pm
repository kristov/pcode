package Pcode::CommandList::Item;

use Moose;

has 'command' => (
    is => 'rw',
    isa => 'Pcode::Command',
    default => sub { [ ] },
    documentation => '',
);

1;
