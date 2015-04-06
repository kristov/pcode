package Pcode::SnapList;

use Moose;
with 'Pcode::Role::List';

sub recalculate_points {
    my ( $self ) = @_;

    my $list = $self->list;

    my %by_str_ref = map( +( "$_" => $_ ), @{ $list } );

    my @ordered = sort { $a cmp $b } keys %by_str_ref;
    my $endx = scalar( @ordered );

    my @comps;

    for ( my $i = 0; $i < $endx; $i++ ) {
        for ( my $j = $i + 1; $j < $endx; $j++ ) {
            push @comps, [ $ordered[$i], $ordered[$j] ];
        }
    }

    my @all_points;

    for my $comp ( @comps ) {
        my ( $obj1, $obj2 ) = ( $by_str_ref{$comp->[0]}, $by_str_ref{$comp->[1]} );
        my @points = $obj1->intersect( $obj2 );
        for my $point ( @points ) {
            push @all_points, $point if $point;
        }
    }

    return @all_points;
}

1;
