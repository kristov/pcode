package Pcode::SnapList;

use Moose;
with 'Pcode::Role::List';

has 'points' => (
    is  => 'rw',
    isa => 'Pcode::PointList',
    default => sub { Pcode::PointList->new(); },
    documentation => "The snap point list",
);

sub translate {
    my ( $self, $x, $y ) = @_;
    $self->foreach( sub {
        my ( $snap ) = @_;
        $snap->translate( $x, $y );
    } );
    $self->recalculate_points;
}

sub add_snap {
    my ( $self, $object ) = @_;
    $self->append( $object );
    $self->recalculate_points;
}

sub detect_point_snap {
    my ( $self, $app, $current_point, $res ) = @_;
    return $self->points->detect_point_snap( $app, $current_point, $res );
}

sub render {
    my ( $self, $app, $cr ) = @_;

    $self->foreach( sub {
        my ( $snap ) = @_;
        $snap->render( $app, $cr );
    } );

    if ( $self->points ) {
        $self->points->foreach( sub {
            my ( $point ) = @_;
            $point->render( $app, $cr );
        } );
    }
}

sub recalculate_points {
    my ( $self ) = @_;

    my $list = $self->list;

    my @non_points = grep { "$_" !~ /Point/ } @{ $list };
    my @stc_points = grep { "$_" =~ /Point/ } @{ $list };

    my %by_str_ref = map( +( "$_" => $_ ), @non_points );

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

    $self->points->clear;
    for my $point ( @all_points ) {
        $self->points->append( $point );
    }

    for my $point ( @stc_points ) {
        $self->points->append( Pcode::Point->new( {
            X => $point->X,
            Y => $point->Y,
            Z => $point->Z,
        } ) );
    }
}

1;
