# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Copyright 2011 Brian Meeker (meeker.brian@gmail.com)

use strict;
use warnings;

use MooseX::Declare;

class Games::Tetravex {
    use Games::Tetravex::Grid;
    use Games::Tetravex::Piece;
    use SDL;
    use SDL::Event;
    use SDLx::App;
    use SDLx::Rect;

    has 'app' => (
	is       => 'ro',
	isa      => 'SDLx::App',
	required => 1,
	handles  => [qw ( run )],
    );

    has 'available_pieces_grid' => (
    );
    
    has 'played_pieces_grid' => (
    );

    has 'current_piece' => (
	is => 'rw',
	isa => 'Games::Tetravex::Piece',
    );

    around BUILDARGS => sub {
	my ($orig, $class, %args) = @_;
	
	my $app = SDLx::App->new(
	    w            => 900,
	    h            => 500,
	    t            => 'Tetravex',
	    exit_on_quit => 1,
	);

	my $assets = $args{assets};
	
	my $font = $assets->file('piece_font.ttf');

	my $available_pieces_grid = initialize_available_pieces($font);
	my $played_pieces_grid = {
	    x => 60,
	    y => 60,
	    pieces => []
	};
	$played_pieces_grid->{pieces}[8] = undef;

	$app->add_event_handler(sub { $self->handle_mouse_click(@_) });
	$app->add_show_handler( sub { $self->show_handler(@_) });

	return $class->$orig(
	    app                    => $app,
	    available_pieces_griid => $available_pieces_grid,
	    played_pieces_grid     => $played_pieces_grid,
	);
    };

    
    
    method handle_mouse_click($event, $app) {
	# We want a drag & drop interface for pieces.
	if ($event->type == SDL_MOUSEBUTTONDOWN and $event->button_button == SDL_BUTTON_LEFT) {
	    my $x = $event->button_x;
	    my $y = $event->button_y;
	    print "mouse clicked at $x, $y\n";
	
	    # Did they click a piece that has been played?
	    my $piece_number;
	    if (($piece_number = piece_at($played_pieces_grid, $x, $y)) != -1) {
		print "clicked played piece #$piece_number\n";
		if (defined $played_pieces_grid->{pieces}[$piece_number]) {
		    $current_piece = remove_piece($played_pieces_grid, $piece_number);
		    $current_piece->{x} = $x;
		    $current_piece->{y} = $y;
		}
	    } elsif (($piece_number = piece_at($available_pieces_grid, $x, $y)) != -1) {
		print "clicked available piece #$piece_number\n";
		if (defined $available_pieces_grid->{pieces}[$piece_number]) {
		    $current_piece = remove_piece($available_pieces_grid, $piece_number);
		    $current_piece->{x} = $x;
		    $current_piece->{y} = $y;
		}
	    }

	} elsif ($event->type == SDL_MOUSEBUTTONUP and $event->button_button == SDL_BUTTON_LEFT) {
	    my $x = $event->button_x;
	    my $y = $event->button_y;
	    print "mouse released at $x, $y\n";

	    # Put the piece back in the grid
	    if (defined $current_piece) {
		my $overlap = get_overlap();
		my $destination = $overlap->[0];
		$destination->{grid}{pieces}[$destination->{grid_index}] = $current_piece->{piece};
		$current_piece = undef;
	    }
	} elsif ($event->type == SDL_MOUSEMOTION and defined $current_piece) {
	    $current_piece->{x} = $event->motion_x;
	    $current_piece->{y} = $event->motion_y;
	}
    }

    method show_handler() {
	# first, we clear the screen
	$app->draw_rect( [ 0, 0, $app->w, $app->h ], 0x000000 );

	# Draw the two grids. The left one is playing grid.
	# The right one holds pieces in reserve.
	draw_grid($self->played_pieces_grid);
	draw_grid($self->available_pieces_grid);

	draw_pieces($self->played_pieces_grid); # playing grid
	draw_pieces($self->available_pieces_grid); # remaining pieces grid

	# Draw the piece being dragged
	if (defined $current_piece) {
	    draw_piece($current_piece->{piece}, $current_piece->{x}, $current_piece->{y});
	}

	$app->update;
    };

    method _initialize_available_pieces($font) {
	my $grid = Games::Tetravex::Grid->new(
	    x => 480,
	    y => 60,
	);

	for my $y (0..2) {
	    for my $x (0..2) {
		my $index = $x + (3 * $y);
		my $x_offset = $grid->x + 121 * $x;
		my $y_offset = $grid->y + 121 * $y;

		# TODO: This could theoretically produce a 10.
		my @values = map { int(rand(10)) } (0..3);
		$grid->pieces->[$index] = Games::Tetravex::Piece->new(
		    x => $x_offset,
		    y => $y_offset,
		    value => \@values,
		    font  => $font,
		);

	    }
	}
	return $grid;
    }
}

# The piece the user is currently dragging.
# It will have two keys:
# from_grid = The grid the user moved the piece from (HASHREF)
# piece = The piece actually being moved (ARRAYREF)
# old_position = The position in the grid it was moved from. (SCALAR)
# x = The x position the mouse is currently at.
# y = The y position the mouse is currently at.
#my $current_piece;
