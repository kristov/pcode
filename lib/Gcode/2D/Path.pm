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
    default => 2,
    documentation => 'How much to go down per cut',
);

has path => (
    is  => 'rw',
    isa => 'Gcode::Path',
    required => 1,
    documentation => 'The commands making up a path',
);

has gcode => (
    is  => 'rw',
    isa => 'ArrayRef',
    default => sub { [ ] },
    documentation => 'The gcode',
);

sub generate {
    my ( $self ) = @_;

    $self->gcode( [] );

    my $nr_full_cuts = int( $self->work_thickness / $self->cut_depth );
    my $remainder = $self->work_thickness - ( $nr_full_cuts * $self->cut_depth );

    my $last_cut_depth = $remainder + $self->overcut;

    $self->comment( "BEGIN " . $self->path->name )
        if $self->path->name;

    $self->set_absolute;
    $self->raise_above_work;

    my $current_depth = 0;

    for my $cut_nr ( 1 .. $nr_full_cuts ) {
        
        $self->move_to( $self->path->start_X, $self->path->start_Y );
        $self->move_down_to( $current_depth );

        $current_depth = $current_depth - $self->cut_depth;

        $self->cut_down_to( $current_depth );

        $self->path->foreach( sub {
            my ( $command ) = @_;
            $self->_add( $command->gcode );
        } );

        $self->raise_above_work;
    }

    $self->move_to( $self->path->start_X, $self->path->start_Y );
    $self->move_down_to( $current_depth );

    $current_depth = $current_depth - $last_cut_depth;

    $self->cut_down_to( $current_depth );

    $self->path->foreach( sub {
        my ( $command ) = @_;
        $self->_add( $command->gcode );
    } );

    $self->comment( "END " . $self->path->name )
        if $self->path->name;

    $self->raise_above_work;
    $self->move_to( 0, 0 );
    $self->move_down_to( 0 );

    return join( "\n", @{ $self->gcode } );
}

sub generate_test {
    my ( $self ) = @_;

    $self->gcode( [] );

    $self->set_absolute;
    $self->raise_above_work;

    $self->move_to( $self->path->start_X, $self->path->start_Y );

    $self->path->foreach( sub {
        my ( $command ) = @_;
        $self->_add( $command->gcode );
    } );

    $self->move_to( 0, 0 );
    $self->move_down_to( 0 );

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

sub move_to {
    my ( $self, $x, $y ) = @_;
    $self->_add( "G0 X%0.2f Y%0.2f", $x, $y );
}

sub comment {
    my ( $self, $comment ) = @_;
    $self->_add( "; %s", $comment );
}

sub _add {
    my ( $self, $pattern, @args ) = @_;
    my $code = @args ? sprintf( $pattern, @args ) : $pattern;
    my $gcode = $self->gcode;
    push @{ $gcode }, $code;
}

1;
