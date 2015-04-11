package Pcode::CommandList;

use Moose;
use Pcode::Point;
use Gcode::Path;
use Gcode::2D::Path;
use Gcode::Command::LineTo;
use Gcode::Command::ArcOffset;

with 'Pcode::Role::List';

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

sub generate_gcode {
    my ( $self ) = @_;

    my $gcode_path = Gcode::Path->new();
    my $first_command = $self->first;

    my $x = $first_command->start->X;
    my $y = $first_command->start->Y;

    $gcode_path->set_start_position( $x, $y );

    $self->foreach( sub {
        my ( $command ) = @_;
        my $gcode_command = $self->generate_gcode_command( $command );
        $gcode_path->add_command( $gcode_command );
    } );

    my $path2d = Gcode::2D::Path->new( {
        work_thickness => 5.4,
        path           => $gcode_path,
    } );

    return $path2d->generate;
}

sub generate_gcode_command {
    my ( $self, $command ) = @_;

    my $gcode;

    if ( $command->isa( 'Pcode::Command::Line' ) ) {
        $gcode = Gcode::Command::LineTo->new( {
            X => $command->end->X,
            Y => $command->end->Y,
        } );
    }
    elsif ( $command->isa( 'Pcode::Command::Arc' ) ) {

        my $center = $command->center;

        my $sX = $command->start->X;
        my $sY = $command->start->Y;

        my $I = $center->X - $sX;
        my $J = $center->Y - $sY;

        $gcode = Gcode::Command::ArcOffset->new( {
            X => $command->end->X,
            Y => $command->end->Y,
            I => $I,
            J => $J,
            clockwise => $command->clockwise,
        } );
    }

    return $gcode;
}

1;
