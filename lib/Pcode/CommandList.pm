package Pcode::CommandList;

use Moose;
use Pcode::Point;
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

1;
