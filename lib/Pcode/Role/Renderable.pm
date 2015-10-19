package Pcode::Role::Renderable;

use Moose::Role;

has 'needs_render' => (
    is  => 'rw',
    isa => 'Bool',
    default => 0,
    documentation => 'Does this thing need to be rendered',
);

1;
