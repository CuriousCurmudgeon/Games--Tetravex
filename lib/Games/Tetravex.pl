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

package Games::Tetravex;

use strict;
use warnings;
use FindBin qw ($Bin);
use lib "$Bin/Tetravex";

use Games::Tetravex::Piece;
use SDL;
use SDL::Event;
use SDLx::App;
use SDLx::Rect;
use SDLx::Text;
use SDL::GFX::Primitives;

my $app = SDLx::App->new(
    w            => 900,
    h            => 500,
    t            => 'Tetravex',
    exit_on_quit => 1,
);

# A piece is a four element array with the numbers, in order, representing
# the sides of the piece clockwise, starting from the top.
my $available_pieces_grid = initialize_available_pieces();
my $played_pieces_grid = {
    x => 60,
    y => 60,
    pieces => []
};
$played_pieces_grid->{pieces}[8] = undef;

# The piece the user is currently dragging.
# It will have two keys:
# from_grid = The grid the user moved the piece from (HASHREF)
# piece = The piece actually being moved (ARRAYREF)
# old_position = The position in the grid it was moved from. (SCALAR)
# x = The x position the mouse is currently at.
# y = The y position the mouse is currently at.
my $current_piece;

$app->add_event_handler( sub {
    my ( $event, $app ) = @_;

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
	}
	elsif (($piece_number = piece_at($available_pieces_grid, $x, $y)) != -1){
	    print "clicked available piece #$piece_number\n";
	    if (defined $available_pieces_grid->{pieces}[$piece_number]) {
		$current_piece = remove_piece($available_pieces_grid, $piece_number);
		$current_piece->{x} = $x;
		$current_piece->{y} = $y;
	    }
	}

    }
    elsif ($event->type == SDL_MOUSEBUTTONUP and $event->button_button == SDL_BUTTON_LEFT) {
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
    }
    elsif ($event->type == SDL_MOUSEMOTION and defined $current_piece) {
	$current_piece->{x} = $event->motion_x;
	$current_piece->{y} = $event->motion_y;
    }
});

$app->add_show_handler( sub {
    # first, we clear the screen
    $app->draw_rect( [ 0, 0, $app->w, $app->h ], 0x000000 );

    # Draw the two grids. The left one is playing grid.
    # The right one holds pieces in reserve.
    draw_grid($played_pieces_grid);
    draw_grid($available_pieces_grid);

    draw_pieces($played_pieces_grid); # playing grid
    draw_pieces($available_pieces_grid); # remaining pieces grid

    # Draw the piece being dragged
    if (defined $current_piece) {
	draw_piece($current_piece->{piece}, $current_piece->{x}, $current_piece->{y});
    }

    $app->update;
});

=head2 draw_grid

Each block in the grid is 120x120, with a one pixel
border between blocks.

=cut

sub draw_grid {
    my ($grid) = @_;

    my $upper_left_x = $grid->{x};
    my $upper_left_y = $grid->{y};
    for my $x (0..2) {
	for my $y (0..2) {
	    $app->draw_rect( [$upper_left_x + 121 * $x, 
			      $upper_left_y + 121 * $y, 
			      120, 120], 0xFFFFFFFF );
	}
    }
}

=head2 draw_pieces

Draw all the pieces in $grid. The x and y coordinates of the upper
left corner of the grid is given by the second and third arguments.

=cut

sub draw_pieces {
    my ($grid) = @_;
    
    my $upper_left_x = $grid->{x};
    my $upper_left_y = $grid->{y};
    for my $y (0..2) {
	for my $x (0..2) {
	    my $piece = $grid->{pieces}[$x + 3 * $y];
	    my $x_offset = $upper_left_x + 121 * $x;
	    my $y_offset = $upper_left_y + 121 * $y;

	    $piece->draw($app) if defined $piece;
	}
    }
}

=head2 draw_piece

Draws the given piece with its upper left corner at ($x_offset, $y_offset)

=cut

=head2 piece_at

=cut

sub piece_at {
    my ($grid, $coord_x, $coord_y) = @_;
    
    my $upper_left_x = $grid->{x};
    my $upper_left_y = $grid->{y};
    for my $y (0..2) {
	for my $x (0..2) {
	    my $piece = $grid->{pieces}[$x + 3 * $y];
	    my $x_offset = $upper_left_x + 121 * $x;
	    my $y_offset = $upper_left_y + 121 * $y;
	    
	    if ($coord_x > $x_offset
		&& $coord_x < $x_offset + 120
		&& $coord_y > $y_offset
		&& $coord_y < $y_offset + 120) {
		return $x + 3 * $y; # The number of the piece selected in the grid
	    }
	}
    }

    return -1;
}

=head2 remove_piece

Remove the piece from the grid and return information about it.

=cut

sub remove_piece {
    my ($grid, $piece_number) = @_;

    my $current_piece = {
	from_grid => $grid,
	piece => $grid->{pieces}[$piece_number],
	old_position => $piece_number,
    };

    # Remove it from the grid
    $grid->{pieces}[$piece_number] = undef;

    return $current_piece;
}

=head2 get_overlap

Returns a hashref of all the grid positions the current_piece
currently overlaps with. The part that overlaps no grid will
be returned as well.

=cut

sub get_overlap {
    # We know that the piece is 120 x 120 and the coordinates we have are in the top left.
    # At most four pieces can be overlapped, or two pieces and nothing
    # TODO: Actually implement this. Currently we just return the overlap as entirely the upper_left position.
    my $x = $current_piece->{x};
    my $y = $current_piece->{y};
    my $piece_number;
    my $overlap;
    if (($piece_number = piece_at($played_pieces_grid, $x, $y)) != -1) {
	$overlap = [
	    {
		grid => $played_pieces_grid,
		grid_index => $piece_number,
		pixels => 120 * 120,
	    }
	];
    }
    elsif (($piece_number = piece_at($available_pieces_grid, $x, $y)) != -1) {
	$overlap = [
	    {
		grid => $available_pieces_grid,
		grid_index => $piece_number,
		pixels => 120 * 120,
	    }
	];
    }
    return $overlap;
}

sub initialize_available_pieces {
    my $grid = {
	x => 480,
	y => 60,
	pieces => [],
    };

    for my $y (0..2) {
	for my $x (0..2) {
	    my $index = $x + (3 * $y);
	    my $x_offset = $grid->{x} + 121 * $x;
	    my $y_offset = $grid->{y} + 121 * $y;

	    $grid->{pieces}[$index] = Games::Tetravex::Piece(
		x => $x_offset,
		y => $y_offset,
		value => map { rand } (0..9),
	    );

	}
    }
}

$app->run;
