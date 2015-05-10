package Pcode::Recipe::Object::Pulley::HTD;

use Moose;
use Math::Trig qw( asin );

use constant PI => 3.14159265;

has 'teeth' => (
    is  => 'rw',
    isa => 'Int',
    default => 30,
    documentation => 'The number of teeth wanted',
);

has 'pitch' => (
    is  => 'rw',
    isa => 'Int',
    default => 5,
    documentation => 'The pitch of the belt in mm',
);

has 'segments' => (
    is      => 'rw',
    isa     => 'Int',
    lazy    => 1,
    builder => '_build_segments',
    documentation => 'The number of spaces between teeth',
);

has 'outside_diameter' => (
    is      => 'rw',
    isa     => 'Num',
    lazy    => 1,
    builder => '_build_outside_diameter',
    documentation => 'Diameter of the pulley wheel',
);

has 'pitch_diameter' => (
    is      => 'rw',
    isa     => 'Num',
    lazy    => 1,
    builder => '_build_pitch_diameter',
    documentation => 'Diameter of the belt tensile cord',
);

has 'data' => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_build_data',
);

sub properties {
    my ( $self ) = @_;
    return [
        {
            name  => 'teeth',
            label => 'Nr. Teeth',
            type  => 'Num',
        },
        {
            name  => 'pitch',
            label => 'Tooth Pitch',
            type  => 'Num',
        },
    ];
}

sub snaps {
    my ( $self, $app ) = @_;

    my $r = $self->R1_center_radius;
    my $R1 = $self->data->{R1};

    my $cpo = $self->connect_point_offset;
    my $ODR = $self->outside_diameter / 2;

    my $nr_teeth = $self->teeth;

    my $PI2 = PI * 2;
    my $rad_per_tooth = $PI2 / $nr_teeth;

    my @snaps;

    for my $tooth_nr ( 0 .. ( $nr_teeth - 1 ) ) {
        my $rad = $tooth_nr * $rad_per_tooth;
        my $x = sprintf( '%0.4f', $r * cos( $rad ) );
        my $y = sprintf( '%0.4f', $r * sin( $rad ) );
        push @snaps, [ 'circle', [ $x, $y, $R1 ] ];

        my $xp1 = sprintf( '%0.4f', $ODR * cos( $rad + $cpo ) );
        my $yp1 = sprintf( '%0.4f', $ODR * sin( $rad + $cpo ) );
        push @snaps, [ 'point', [ $xp1, $yp1 ] ];

        my $xp2 = sprintf( '%0.4f', $ODR * cos( $rad - $cpo ) );
        my $yp2 = sprintf( '%0.4f', $ODR * sin( $rad - $cpo ) );
        push @snaps, [ 'point', [ $xp2, $yp2 ] ];
    }

    push @snaps, [ 'circle', [ 0, 0, $ODR ] ];
    push @snaps, [ 'circle', [ 0, 0, $self->R1_center_radius ] ];

    for my $snap ( @snaps ) {
        my ( $name, $args ) = @{ $snap };

        my $object = $app->create_object( 'snap', $name, $args );
        if ( $object ) {
            $app->snaps->append( $object );
        }
    }
}

sub connect_point_offset {
    my ( $self ) = @_;

    my $R1 = $self->data->{R1};
    my $R0 = $self->data->{R0};

    my $hyp = $self->outside_diameter / 2;
    my $opp = $R1 + $R0;

    return asin( $opp / $hyp );
}

=item tooth_top_radius

Radius from the center of the pulley to the top of the tooth. Note: the
top of the tooth is facing inwards, is the inner most part of the belt,
and so it's the smallest radius relative to the center of the tooth.

=cut

sub tooth_top_radius {
    my ( $self ) = @_;
    
    my $U = $self->data->{U};
    my $h = $self->data->{h};
    my $U2toothtop = $U + $h;

    return sprintf( '%0.4f', ( $self->pitch_diameter / 2 ) - $U2toothtop );
}

=item R1_center_radius

Radius from center of the pulley to the center of the radius that shapes
the top of the tooth. This is used to mark the point around which the tooth
shape pivots.

=cut

sub R1_center_radius {
    my ( $self ) = @_;
    my $tooth_top_radius = $self->tooth_top_radius;
    my $R1 = $self->data->{R1};
    return $tooth_top_radius + $R1;
}

sub _build_outside_diameter {
    my ( $self ) = @_;
    my $U = $self->data->{U};
    return sprintf( '%0.4f', $self->pitch_diameter - ( 2 * $U ) );
}

sub _build_pitch_diameter {
    my ( $self ) = @_;
    return sprintf( '%0.4f', ( $self->teeth * $self->pitch ) / PI );
}

sub _build_segments {
    my ( $self ) = @_;
    return $self->teeth - 1;
}

sub BUILD {
    my ( $self ) = @_;

    my $pitch = $self->pitch;
    my $data = $self->data;

    die "Sorry, I do not have data about pitch $pitch"
        if !keys %{ $data };
}

sub _build_data {
    my ( $self ) = @_;

    my $data = {};
    
    my $header = <DATA>;
    chomp $header;

    my @head = split( /\s+/, $header );
    my $idx = 0;
    my %idx2label = map { $idx++ => $_ } @head;

    while ( <DATA> ) {
        chomp;
        my @items = split( /\s+/ );
        my $type = shift @items;

        next if $type ne $self->pitch;

        $idx = 1;
        for my $item ( @items ) {
            my $label = $idx2label{$idx};
            $data->{$label} = $item;
            $idx++;
        }

        last;
    }
    return $data;
}

1;

=item DATA

        _______________________________________________  _______________
                                                                |    |
                                                                |i   |H
        __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __  _____  |    |
                                                           |U   |    |
        ______________                   ______________  __|____|__  |
                      \                 /                       |    |
                       |       *       | \                      |h   |
                       |      /        |  \                     |    |
                        \    /R1      /    \R0                  |    |
                         \___________/  ________________________|____|__


    Pitch ==> The distance between the centers of the teeth when the belt is
              flat. As the belt curves around a pulley the distance between
              the top of the teeth shrinks, however the distance along the
              reenforcing inside the belt remains constant.

    H ==> Total height from back of the belt, to the top of the tooth.

    h ==> Height of the tooth.

    i ==> Thickness of the belt.

    W ==> The width of the tooth at the base. Strangely: greater than double
          R1 and less than double R2 plus double R0.

    U ==> Distance from belt reenforcing to inside of the belt. This was a
          fairly difficult number to come across, and I ended up calculating
          it from data sheets that gave the OD and PD.

    R0 ==> A small radius for the join between the tooth and the belt.

    R1 ==> The radius of the top of the tooth. The center of this radius
           can be calculated relative to the reenforcing of the belt using U
           and h.

=cut

__DATA__
Pitch   H       h       i       W       U       R0      R1
5       3.8     2.06    1.74    3.05    0.57    0.43    1.49
