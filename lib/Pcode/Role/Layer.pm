package Pcode::Role::Layer;

use Moose::Role;
use Cairo;

use constant GREYED_ALPHA => 0.3;

has 'needs_render' => (
    is => 'rw',
    isa => 'Bool',
    default => 1,
    documentation => 'Is a redraw in order',
);

has 'surface' => (
    is  => 'rw',
    isa => 'Cairo::ImageSurface',
    documentation => "Cairo surface we are drawing to",
);

has 'greyed' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
    documentation => 'Grey this layer when painting',
);

sub create_surface {
    my ( $self, $app ) = @_;
    my $surface = Cairo::ImageSurface->create( 'argb32', $app->da_width, $app->da_height );
    $self->surface( $surface );
}

sub render {
    my ( $self, $app, $parent_cr ) = @_;

    if ( $self->needs_render ) {
        $self->create_surface( $app );
    }

    my $surface = $self->surface();
    
    if ( $self->needs_render ) {
        my $cr = Cairo::Context->create( $surface );
        $self->render_layer( $app, $cr );
        $self->needs_render( 0 );
    }

    $parent_cr->set_source_surface( $surface, 0, 0 );
    if ( $self->greyed ) {
        $parent_cr->paint_with_alpha( GREYED_ALPHA );
    }
    else {
        $parent_cr->paint;
    }
}

1;
