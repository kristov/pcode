#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use constant SCREEN_HEIGHT => 800;

use Pcode::Point;
use_ok( 'Pcode::Util::Coord' );

my $coord = Pcode::Util::Coord->new( { x_offset => 0, y_offset => 0 } );

my $point1 = Pcode::Point->new( { X => 6, Y => 4 } );
my $point2 = Pcode::Point->new( { X => 8, Y => 6 } );
my $point3 = Pcode::Point->new( { X => 8, Y => 4 } );

$coord->x_offset( 5 );
$coord->y_offset( 3 );
$coord->zoom( 2 );

my ( $trans1 ) = $coord->translate_to_screen_coords( SCREEN_HEIGHT, $point1 );
is( $trans1->X, 2, 'translated point 1 X' );
is( $trans1->Y, SCREEN_HEIGHT - 2, 'translated point 1 Y' );

my ( $trans2, $trans3 ) = $coord->translate_to_screen_coords( SCREEN_HEIGHT, $point2, $point3 );
is( $trans2->X, 6, 'translated point 2 X' );
is( $trans2->Y, SCREEN_HEIGHT - 6, 'translated point 2 Y' );
is( $trans3->X, 6, 'translated point 3 X' );
is( $trans3->Y, SCREEN_HEIGHT - 2, 'translated point 3 Y' );
