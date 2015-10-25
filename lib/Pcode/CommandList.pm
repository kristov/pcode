package Pcode::CommandList;

use Moose;
use Pcode::Point;
use Gcode::Path;
use Gcode::2D::Path;
use Gcode::Command::LineTo;
use Gcode::Command::ArcOffset;

with 'Pcode::Role::List';

has invert_axis => (
    is  => 'rw',
    isa => 'Bool',
    default => 0,
);

sub detect_point_snap {
    my ( $self, $app, $current_point, $res ) = @_;

    my $found_point;

    $self->foreach( sub {
        my ( $command ) = @_;

        for my $point ( $command->start, $command->end ) {
            if ( $point->distance( $current_point ) <= $res ) {
                $point->hover( 1 );
                if ( !$app->hover_point || !$app->hover_point->equal( $point ) ) {
                    $app->invalidate;
                    $app->hover_point( $point );
                }
                $found_point = $point;
            }
            else {
                $point->hover( 0 );
            }
        }
    } );

    return $found_point;
}

sub detect_line_snap {
    my ( $self, $app, $current_point ) = @_;

    my $found_line;

    $self->foreach( sub {
        my ( $command ) = @_;

        if ( $command->distance_to_point( $current_point ) <= 10 ) {
            $command->hover( 1 );
            if ( !$app->hover_line || !$app->hover_line->equal( $command ) ) {
                $app->invalidate;
                $app->hover_line( $command );
            }
            $found_line = $command;
        }
        else {
            $command->hover( 0 );
        }
    } );

    return $found_line;
}

sub stringify {
    my ( $self ) = @_;

    my @commands;
    $self->foreach( sub {
        my ( $command ) = @_;
        push @commands, $command->stringify;
    } );

    return join( "\n", @commands );
}

sub bounding_points {
    my ( $self ) = @_;

    my $minx;
    my $miny;
    my $maxx;
    my $maxy;

    return if $self->count == 0;

    $self->foreach( sub {
        my ( $command ) = @_;

        my $start = $command->start;
        my $end = $command->end;

        $minx = $start->X if !defined $minx || $start->X < $minx;
        $miny = $start->Y if !defined $miny || $start->Y < $miny;
        $maxx = $start->X if !defined $maxx || $start->X > $maxx;
        $maxy = $start->Y if !defined $maxy || $start->Y > $maxy;

        $minx = $end->X if !defined $minx || $end->X < $minx;
        $miny = $end->Y if !defined $miny || $end->Y < $miny;
        $maxx = $end->X if !defined $maxx || $end->X > $maxx;
        $maxy = $end->Y if !defined $maxy || $end->Y > $maxy;
    } );

    return (
        Pcode::Point->new( { X => $minx, Y => $miny } ),
        Pcode::Point->new( { X => $maxx, Y => $maxy } ),
    );
}

sub generate_gcode {
    my ( $self, $args ) = @_;

    my ( $mX, $mY ) = ( 0, 0 );
    if ( $args->{offset} ) {
        $mX = $args->{offset}->{X};
        $mY = $args->{offset}->{Y};
    }

    my $gcode_path = Gcode::Path->new();
    my $first_command = $self->first;

    $gcode_path->name( $args->{name} )
        if $args->{name};

    return if !$first_command;

    my ( $x, $y );
    if ( $self->invert_axis ) {
        $x = $first_command->start->Y;
        $y = $first_command->start->X;
    }
    else {
        $x = $first_command->start->X;
        $y = $first_command->start->Y;
    }

    $x = $x - $mX;
    $y = $y - $mY;

    $gcode_path->set_start_position( $x, $y );

    $self->foreach( sub {
        my ( $command ) = @_;
        my $gcode_command = $self->generate_gcode_command( $command, $mX, $mY );
        $gcode_path->add_command( $gcode_command );
    } );

    my $path2d = Gcode::2D::Path->new( {
        work_thickness => $args->{depth},
        overcut        => $args->{overcut},
        path           => $gcode_path,
    } );

    return $path2d;
}

sub generate_gcode_command {
    my ( $self, $command, $mX, $mY ) = @_;

    $mX ||= 0;
    $mY ||= 0;

    my $gcode;

    my ( $x, $y );
    if ( $self->invert_axis ) {
        $x = $command->end->Y;
        $y = $command->end->X;
    }
    else {
        $x = $command->end->X;
        $y = $command->end->Y;
    }

    $x = $x - $mX;
    $y = $y - $mY;

    if ( $command->isa( 'Pcode::Command::Line' ) ) {
        $gcode = Gcode::Command::LineTo->new( {
            X => $x,
            Y => $y,
            feed_rate => 100,
        } );
    }
    elsif ( $command->isa( 'Pcode::Command::Arc' ) ) {

        my $center = $command->center;

        my ( $cX, $cY );
        my ( $sX, $sY );
        if ( $self->invert_axis ) {
            $sX = $command->start->Y;
            $sY = $command->start->X;
            $cX = $center->Y;
            $cY = $center->X;
        }
        else {
            $sX = $command->start->X;
            $sY = $command->start->Y;
            $cX = $center->X;
            $cY = $center->Y;
        }

        $sX = $sX - $mX;
        $sY = $sY - $mY;
        $cX = $cX - $mX;
        $cY = $cY - $mY;

        my $I = $cX - $sX;
        my $J = $cY - $sY;

        $gcode = Gcode::Command::ArcOffset->new( {
            X => $x,
            Y => $y,
            I => $I,
            J => $J,
            clockwise => $command->clockwise,
            feed_rate => 100,
        } );
    }

    return $gcode;
}

1;
