package Pcode::Path;

use Moose;
use Pcode::PointList;
use Pcode::CommandList;

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

sub detect_point_snap {
    my ( $self, $app, $x, $y ) = @_;
    return $self->commands->detect_point_snap( $app, $x, $y );
}

sub detect_line_snap {
    my ( $self, $app, $x, $y ) = @_;
    return $self->commands->detect_line_snap( $app, $x, $y );
}

sub clear {
    my ( $self ) = @_;
    $self->commands->clear;
    $self->tool_paths->clear;
}

sub delete_last {
    my ( $self ) = @_;
    $self->commands->pop;
    $self->regenerate_tool_paths;
}

sub stringify {
    my ( $self ) = @_;
    return $self->commands->stringify;
}

sub append_command {
    my ( $self, $command ) = @_;
    $self->commands->append( $command );
    $self->regenerate_tool_paths;
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
            my $first_generated = $generated[0];
            my $last_generated = $generated[-1];
            $first_path->start( $last_generated->start );
        }
    }

    for my $path ( @paths ) {
        $self->tool_paths->append( $path );
    }
}

sub path_between {
    my ( $self, $prev_command, $command, $prev_path ) = @_;

    my @paths;
    my $path = $command->parallel( 40 );

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
    
    if ( $point1 && $point2 ) {
        if ( $commandA->point_within_arc( $point1 ) && $commandB->point_within_arc( $point1 ) ) {
            $pathA->end( $point1 );
            $pathB->start( $point1 );
            push @paths, $pathA;
            push @paths, $pathB;
        }
        elsif ( $commandA->point_within_arc( $point2 ) && $commandB->point_within_arc( $point2 ) ) {
            $pathA->end( $point2 );
            $pathB->start( $point2 );
            push @paths, $pathA;
            push @paths, $pathB;
        }
        else {
            my $new_path = Pcode::Command::Arc->new( {
                start  => $pathA->end,
                end    => $pathB->start,
                radius => 40,
            } );
            push @paths, $pathA;
            push @paths, $new_path;
            push @paths, $pathB;
        }
    }
    else {
        my $new_path = Pcode::Command::Arc->new( {
            start  => $pathA->end,
            end    => $pathB->start,
            radius => 40,
        } );
        push @paths, $pathA;
        push @paths, $new_path;
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

    my $point1d = $point1->distance( $commandA->end );
    my $point2d = $point2->distance( $commandA->end );
    my $closest = $point2d > $point1d ? $point1 : $point2;

    my @paths;

    $pathA->end( $closest );
    $pathB->start( $closest );
    push @paths, $pathA;
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
        push @paths, $pathA;
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

    my $point1d = $point1->distance( $commandA->end );
    my $point2d = $point2->distance( $commandA->end );
    my $closest = $point2d > $point1d ? $point1 : $point2;

    my @paths;

    $pathA->end( $closest );
    $pathB->start( $closest );
    push @paths, $pathA;
    push @paths, $pathB;

    return @paths;
}

sub render {
    my ( $self, $app, $cr ) = @_;
    $self->render_commands( $app, $cr );
    $self->render_tool_paths( $app, $cr );
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

    my $objects = [];

    $self->commands->foreach( sub {
        my ( $command ) = @_;
        push @{ $objects }, $command->serialize;
    } );

    return { commands => $objects };
}

1;
