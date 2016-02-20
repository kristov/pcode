package Pcode::App::ObjectTree;

use Moose;
use Glib qw( TRUE FALSE );

has 'app' => (
    is  => 'rw',
    isa => 'Pcode::App',
    required => 1,
    documentation => 'Invalidate when things change',
);

has 'widget' => (
    is  => 'rw',
    isa => 'Object',
    documentation => 'The widget to render',
);

has 'tree_store' => (
    is  => 'rw',
    isa => 'Gtk2::TreeStore',
    documentation => 'The thing',
);

has 'tree_view' => (
    is  => 'rw',
    isa => 'Gtk2::TreeView',
    documentation => 'The other thing',
);

sub BUILD {
    my ( $self ) = @_;

    my $sw = Gtk2::ScrolledWindow->new( undef, undef );

    $sw->set_shadow_type( 'etched-out' );
    $sw->set_policy( 'automatic', 'automatic' );
    $sw->set_size_request( 300, 200 );
    $sw->set_border_width( 5 );

    my $tree_store = Gtk2::TreeStore->new( qw/ Glib::String Glib::Scalar / );
    $self->tree_store( $tree_store );
 
    my $tree_view = Gtk2::TreeView->new( $tree_store );
    $self->tree_view( $tree_view );

    my $tree_column = Gtk2::TreeViewColumn->new();
    $tree_column->set_title( "Path objects" );

    my $renderer = Gtk2::CellRendererText->new;
    $tree_column->pack_start( $renderer, FALSE );
    $tree_column->add_attribute( $renderer, text => 0 );

    $tree_view->append_column( $tree_column );

    #$tree_view->set_search_column( 0 );
    #$tree_column->set_sort_column_id( 0 );

    $tree_view->set_reorderable( TRUE );
    
    $sw->add( $tree_view );

    $tree_view->get_selection->signal_connect( changed => sub {
        my ( $selection ) = @_;
        my ( $model, $iter ) = $selection->get_selected;
        if ( $iter ) {
            my $object = $model->get( $iter, 1 );
            if ( $object ) {
                my $iter_parent = $model->iter_parent( $iter );
                my $parent_object;
                if ( $iter_parent ) {
                    $parent_object = $model->get( $iter_parent, 1 );
                }
                $self->app->object_selected( $object, $parent_object );
            }
        }
    } );

    $self->widget( $sw );
}

sub build_tree {
    my ( $self ) = @_;

    my $tree_store = $self->tree_store;

    $self->tree_view->set_model( undef );
    $tree_store->clear;

    $self->app->path_groups->foreach( sub {
        my ( $path_group ) = @_;
        
        my $path_group_iter = $tree_store->append( undef );
        $tree_store->set( $path_group_iter, 0 => $path_group->name );
        $tree_store->set( $path_group_iter, 1 => $path_group );

        $path_group->paths->foreach( sub {
            my ( $path ) = @_;

            my $path_iter = $tree_store->append( $path_group_iter );
            $tree_store->set( $path_iter, 0 => $path->name );
            $tree_store->set( $path_iter, 1 => $path );

            $path->commands->foreach( sub {
                my ( $command ) = @_;

                my $data = $command->serialize;
                #my $str = "$data";
                my $name = $data->[0];
                my @values = @{ $data->[1] };
                @values = map { defined $_ ? sprintf( '%0.2f', $_ ) : 0 } @values;
                my $str = sprintf( '%s(%s)', $data->[0], join( ',', @values ) );

                my $command_iter = $tree_store->append( $path_iter );
                $tree_store->set( $command_iter, 0 => "$str" );
                $tree_store->set( $command_iter, 1 => $command );
            } );
        } );
    } );

    $self->tree_view->set_model( $tree_store );
    $self->tree_view->expand_all;
}

1;
