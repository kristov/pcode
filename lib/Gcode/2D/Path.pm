package Gcode::2D::Path;

use Moose;

has work_thickness => (
    is  => 'rw',
    isa => 'Num',
    required => 1,
    documentation => 'The thickness of the work in mm',
);

has work_clearance => (
    is  => 'rw',
    isa => 'Num',
    default => 2,
    documentation => 'How high to raise above the work between cuts',
);

has overcut => (
    is  => 'rw',
    isa => 'Num',
    default => 0,
    documentation => 'How much to continue below the work',
);

has cut_depth => (
    is  => 'rw',
    isa => 'Num',
    default => 0.5,
    documentation => 'How much to go down per cut',
);

has path => (
    is  => 'rw',
    isa => 'ArrayRef',
    default => sub { [ ] },
    documentation => 'The commands making up a path',
);

has gcode => (
    is  => 'rw',
    isa => 'ArrayRef',
    default => sub { [ ] },
    documentation => 'The gcode',
);

has start_x => (
    is  => 'rw',
    isa => 'Num',
    default => 0,
    documentation => 'The path starting X',
);

has start_y => (
    is  => 'rw',
    isa => 'Num',
    default => 0,
    documentation => 'The path starting Y',
);

sub set_start_position {
    my ( $self, $x, $y ) = @_;
    $self->start_x( $x );
    $self->start_y( $y );
}

sub add_command {
    my ( $self, $command ) = @_;
    my $path = $self->path;
    push @{ $path }, $command;
    $self->path( $path );
}

sub generate {
    my ( $self ) = @_;

    my $nr_full_cuts = int( $self->work_thickness / $self->cut_depth );
    my $remainder = $self->work_thickness - ( $nr_full_cuts * $self->cut_depth );

    my $last_cut_depth = $remainder + $self->overcut;

    $self->set_absolute;
    $self->raise_above_work;

    my $current_depth = 0;

    for my $cut_nr ( 1 .. $nr_full_cuts ) {
        
        $self->move_to_start;
        $self->move_down_to( $current_depth );

        $current_depth = $current_depth - $self->cut_depth;

        $self->cut_down_to( $current_depth );

        for my $command ( @{ $self->path } ) {
            $self->_add( $command );
        }

        $self->raise_above_work;
    }

    $self->move_to_start;
    $self->move_down_to( $current_depth );

    $current_depth = $current_depth - $last_cut_depth;

    $self->cut_down_to( $current_depth );

    for my $command ( @{ $self->path } ) {
        $self->_add( $command );
    }

    $self->raise_above_work;

    return join( "\n", @{ $self->gcode } );
}

sub set_absolute {
    my ( $self ) = @_;
    $self->_add( "G90" );
}

sub raise_above_work {
    my ( $self ) = @_;
    $self->_add( "G0 Z%0.2f", $self->work_clearance );
}

sub move_down_to {
    my ( $self, $depth ) = @_;
    $self->_add( "G0 Z%0.2f", $depth );
}

sub cut_down_to {
    my ( $self, $depth ) = @_;
    $self->_add( "G1 Z%0.2f", $depth );
}

sub move_to_start {
    my ( $self ) = @_;
    $self->_add( "G0 X%0.2f Y%0.2f", $self->start_x, $self->start_y );
}

sub _add {
    my ( $self, $pattern, @args ) = @_;
    my $code = @args ? sprintf( $pattern, @args ) : $pattern;
    my $gcode = $self->gcode;
    push @{ $gcode }, $code;
}

1;
