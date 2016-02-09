package Pcode::Path;

use Moose;
use Pcode::PointList;
use Pcode::CommandList;

with 'Pcode::Role::Layer';

has 'commands' => (
    is  => 'rw',
    isa => 'Pcode::CommandList',
    default => sub { return Pcode::CommandList->new() },
    documentation => 'List of commands',
);

has 'tool_paths' => (
    is  => 'rw',
    isa => 'Pcode::CommandList',
    default => sub { return Pcode::CommandList->new() },
    documentation => 'List of tool paths',
);

has 'do_render_commands' => (
    is  => 'rw',
    isa => 'Bool',
    default => 1,
    documentation => 'Do we render the path?',
);

has 'do_render_tool_paths' => (
    is  => 'rw',
    isa => 'Bool',
    default => 1,
    documentation => 'Do we render the tool path?',
);

has name => (
    is  => 'rw',
    isa => 'Str',
    documentation => 'The name of the path',
);

has 'tool_radius' => (
    is  => 'rw',
    isa => 'Num',
    default => 1.5,
    documentation => 'Tool radius in mm',
);

has depth => (
    is  => 'rw',
    isa => 'Num',
    required => 1,
    default => 4.8,
    documentation => 'The depth of the cut in mm',
);

has 'overcut' => (
    is  => 'rw',
    isa => 'Num',
    default => 0.2,
    documentation => 'How much to cut under the depth',
);

has 'flip' => (
    is  => 'rw',
    isa => 'Bool',
    default => 0,
    documentation => 'Flip tool path to other side',
);

sub properties {
    my ( $self ) = @_;
    return [
        {
            name  => 'name',
            label => 'Name',
            type  => 'Str',
        },
        {
            name  => 'tool_radius',
            label => 'Tool radius',
            type  => 'Num',
            hook  => sub {
                my ( $self ) = @_;
                $self->regenerate_tool_paths;
                $self->needs_render( 1 );
            },
        },
        {
            name  => 'needs_render',
            label => 'Needs render',
            type  => 'Bool',
            hook  => sub {
                my ( $self ) = @_;
            },
        },
        {
            name  => 'flip',
            label => 'Flip',
            type  => 'Bool',
            hook  => sub {
                my ( $self ) = @_;
                $self->regenerate_tool_paths;
                $self->needs_render( 1 );
            },
        },
        {
            name  => 'do_render_tool_paths',
            label => 'Render tool path?',
            type  => 'Bool',
            hook  => sub {
                my ( $self ) = @_;
                $self->needs_render( 1 );
            },
        },
        {
            name  => 'depth',
            label => 'Depth',
            type  => 'Num',
        },
        {
            name  => 'overcut',
            label => 'Overcut',
            type  => 'Num',
        },
    ];
}

sub detect_point_snap {
    my ( $self, $app, $point, $res ) = @_;
    return $self->commands->detect_point_snap( $app, $point, $res );
}

sub detect_line_snap {
    my ( $self, $app, $point ) = @_;
    return $self->commands->detect_line_snap( $app, $point );
}

sub clear {
    my ( $self ) = @_;
    $self->commands->clear;
    $self->tool_paths->clear;
    $self->needs_render( 1 );
}

sub select {
    my ( $self, $selected_command ) = @_;
    $self->commands->foreach( sub {
        my ( $command ) = @_;
        $command->hover( 0 );
    } );
    $selected_command->hover( 1 );
    $self->needs_render( 1 );
}

sub nr_commands {
    my ( $self ) = @_;
    return $self->commands->count;
}

sub delete_last {
    my ( $self ) = @_;
    $self->commands->pop;
    $self->regenerate_tool_paths;
    $self->needs_render( 1 );
}

sub stringify {
    my ( $self ) = @_;
    return $self->commands->stringify;
}

sub append_command {
    my ( $self, $command ) = @_;
    $self->commands->append( $command );
    $self->needs_render( 1 );
}

sub last_command {
    my ( $self ) = @_;
    return $self->commands->last;
}

sub bounding_points {
    my ( $self ) = @_;
    return $self->commands->bounding_points;
}

sub regenerate_tool_paths {
    my ( $self ) = @_;

    $self->tool_paths->clear;

    my @paths;
    my $prev_command;
    my $prev_path;
    my $first_command;
    my $first_path;

    $self->commands->foreach( sub {
        my ( $command ) = @_;

        my @generated = $self->path_between( $prev_command, $command, $prev_path );
        for my $path ( @generated ) {
            push @paths, $path;
        }
        $prev_path = $paths[-1];

        $first_path = $paths[0] if !$first_path;
        $first_command = $command if !$first_command;

        $prev_command = $command;
    } );

    if ( $prev_command ) {
        if ( $prev_command->end->equal( $first_command->start ) ) {
            my @generated = $self->path_between( $prev_command, $first_command, $prev_path );
            if ( @generated ) {
                my $last_generated = $generated[-1];
                $first_path->start( $last_generated->start );
            }
            elsif ( $paths[-1]->end->equal( $first_path->start ) ) {
                $first_path->start( $paths[-1]->end );
            }
        }
    }

    for my $path ( @paths ) {
        $self->tool_paths->append( $path );
    }
}

sub path_between {
    my ( $self, $prev_command, $command, $prev_path ) = @_;

    my @paths;
    my $path = $command->parallel( $self->tool_radius, $self->flip );

    if ( $prev_path ) {
        if ( $prev_command->does( 'Pcode::Role::ArcLike' ) && $command->does( 'Pcode::Role::ArcLike' ) ) {
            push @paths, $self->arc_to_arc( {
                commandA => $prev_command,
                commandB => $command,
                pathA    => $prev_path,
                pathB    => $path,
            } );
        }
        elsif ( $prev_command->does( 'Pcode::Role::ArcLike' ) && $command->does( 'Pcode::Role::LineLike' ) ) {
            push @paths, $self->arc_to_line( {
                commandA => $prev_command,
                commandB => $command,
                pathA    => $prev_path,
                pathB    => $path,
            } );
        }
        elsif ( $prev_command->does( 'Pcode::Role::LineLike' ) && $command->does( 'Pcode::Role::LineLike' ) ) {
            push @paths, $self->line_to_line( {
                commandA => $prev_command,
                commandB => $command,
                pathA    => $prev_path,
                pathB    => $path,
            } );
        }
        elsif ( $prev_command->does( 'Pcode::Role::LineLike' ) && $command->does( 'Pcode::Role::ArcLike' ) ) {
            push @paths, $self->line_to_arc( {
                commandA => $prev_command,
                commandB => $command,
                pathA    => $prev_path,
                pathB    => $path,
            } );
        }
    }
    else {
        push @paths, $path;
    }

    return @paths;
}

sub arc_to_arc {
    my ( $self, $args ) = @_;

    my $commandA = $args->{commandA};
    my $commandB = $args->{commandB};
    my $pathA    = $args->{pathA};
    my $pathB    = $args->{pathB};

    my @paths;

    my ( $point1, $point2 ) = $pathB->intersection_arc( $pathA );
    
    if ( $pathA->end->equal( $pathB->start ) ) {
        push @paths, $pathB;
        return @paths;
    }
    
    if ( $point1 && $point2 ) {
        if ( $commandA->point_within_arc( $point1 ) && $commandB->point_within_arc( $point1 ) ) {
            $pathA->end( $point1 );
            $pathB->start( $point1 );
            push @paths, $pathB;
        }
        elsif ( $commandA->point_within_arc( $point2 ) && $commandB->point_within_arc( $point2 ) ) {
            $pathA->end( $point2 );
            $pathB->start( $point2 );
            push @paths, $pathB;
        }
        else {
            my $new_path = Pcode::Command::Arc->new( {
                start  => $pathA->end,
                end    => $pathB->start,
                radius => $self->tool_radius,
            } );
            if ( !$new_path->start->equal( $new_path->end ) ) {
                push @paths, $new_path;
            }
            push @paths, $pathB;
        }
    }
    else {
        my $new_path = Pcode::Command::Arc->new( {
            start  => $pathA->end,
            end    => $pathB->start,
            radius => $self->tool_radius,
        } );
        if ( !$new_path->start->equal( $new_path->end ) ) {
            push @paths, $new_path;
        }
        push @paths, $pathB;
    }

    return @paths;
}

sub arc_to_line {
    my ( $self, $args ) = @_;

    my $commandA = $args->{commandA};
    my $commandB = $args->{commandB};
    my $pathA    = $args->{pathA};
    my $pathB    = $args->{pathB};

    my ( $point1, $point2 ) = $pathA->intersection_line( $pathB );

    my @paths;

    if ( !$point1 && !$point2 ) {
        my $new_path = Pcode::Command::Line->new( {
            start  => $pathA->end,
            end    => $pathB->start,
        } );
        push @paths, $new_path;
        push @paths, $pathB;
        return @paths;
    }

    my $closest;
    if ( !$point2 ) {
        $closest = $point1;
    }
    else {
        my $point1d = $point1->distance( $commandA->end );
        my $point2d = $point2->distance( $commandA->end );
        $closest = $point2d > $point1d ? $point1 : $point2;
    }

    $pathA->end( $closest );
    $pathB->start( $closest );
    push @paths, $pathB;

    return @paths;
}

sub line_to_line {
    my ( $self, $args ) = @_;

    my $commandA = $args->{commandA};
    my $commandB = $args->{commandB};
    my $pathA    = $args->{pathA};
    my $pathB    = $args->{pathB};

    my @paths;

    my ( $point ) = $pathA->intersection_imaginary_line( $pathB );
    if ( $point ) {
        $pathA->end( $point );
        $pathB->start( $point );
        push @paths, $pathB;
    }

    return @paths;
}

sub line_to_arc {
    my ( $self, $args ) = @_;

    my $commandA = $args->{commandA};
    my $commandB = $args->{commandB};
    my $pathA    = $args->{pathA};
    my $pathB    = $args->{pathB};

    my ( $point1, $point2 ) = $pathB->intersection_line( $pathA );

    my @paths;

    if ( !$point1 && !$point2 ) {
        my $new_path = Pcode::Command::Line->new( {
            start  => $pathA->end,
            end    => $pathB->start,
        } );
        push @paths, $new_path;
        push @paths, $pathB;
        return @paths;
    }

    my $closest;
    if ( !$point2 ) {
        $closest = $point1;
    }
    else {
        my $point1d = $point1->distance( $commandA->end );
        my $point2d = $point2->distance( $commandA->end );
        $closest = $point2d > $point1d ? $point1 : $point2;
    }

    $pathA->end( $closest );
    $pathB->start( $closest );
    push @paths, $pathB;

    return @paths;
}

sub render_layer {
    my ( $self, $app, $cr ) = @_;
    $self->render_commands( $app, $cr )
        if $self->do_render_commands;
    $self->render_tool_paths( $app, $cr )
        if $self->do_render_tool_paths;
}

sub render_commands {
    my ( $self, $app, $cr ) = @_;

    $self->commands->foreach( sub {
        my ( $command ) = @_;
        $command->render( $app, $cr );
    } );
}

sub render_tool_paths {
    my ( $self, $app, $cr ) = @_;

    $self->tool_paths->foreach( sub {
        my ( $command ) = @_;
        $command->dashed( 1 );
        $command->render( $app, $cr );
    } );
}

sub serialize {
    my ( $self ) = @_;
    return {
        name        => $self->name,
        tool_radius => $self->tool_radius,
        depth       => $self->depth,
        overcut     => $self->overcut,
        flip        => $self->flip,
        commands    => $self->commands->serialize,
    };
}

sub translate {
    my ( $self, $x, $y ) = @_;
    $self->commands->foreach( sub {
        my ( $command ) = @_;
        $command->translate( $x, $y );
    } );
    $self->regenerate_tool_paths;
}

sub generate_gcode {
    my ( $self, $machine_center ) = @_;
    return $self->tool_paths->generate_gcode( {
        offset  => {
            X => $machine_center->X,
            Y => $machine_center->Y,
        },
        depth   => $self->depth,
        overcut => $self->overcut,
        name    => $self->name,
    } );
}

1;
