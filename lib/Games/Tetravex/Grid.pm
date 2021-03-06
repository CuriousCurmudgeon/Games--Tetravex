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

class Games::Tetravex::Grid {
    use Games::Tetravex::Piece;
    use SDLx::Rect;
    use SDL::Surface;

    has 'pieces' => (
	is  => 'ro',
	isa => 'ArrayRef',
	default => sub { my @pieces = map { undef } (0..8); return \@pieces },
    );

    has ['x', 'y'] => (
	is  => 'rw',
	isa => 'Int',
    );

    # Does this grid require that all pieces be in valid positions?
    has 'requires_valid' => (
	is  => 'ro',
	isa => 'Bool',
    );

    # The coordinates of the upper left corner of
    # each position in the grid.
    has 'index_coords' => (
	is       => 'rw',
	isa      => 'ArrayRef',
	builder  => '_build_index_coords',
	lazy     => 1,
	init_arg => undef,
    );

    method draw($surface) {
	# Draw the actual grid
	# Each block in the grid is 120x120, with a one pixel
	# border between blocks.
	for my $x (0..2) {
	    for my $y (0..2) {
		$surface->draw_rect( [$self->x + 121 * $x,
				  $self->y + 121 * $y,
				  120, 120], 0xFFFFFFFF );
	    }
	}
	
	# Draw the pieces on the grid
	for my $y (0..2) {
	    for my $x (0..2) {
		my $piece = $self->pieces->[$x + 3 * $y];
		$piece->draw($surface) if defined $piece;
	    }
	}
    }
    
    # Get the number of the piece, if any, at the given coordinates.
    method grid_index_at($x, $y) {
	for my $grid_y (0..2) {
	    for my $grid_x (0..2) {
		my $coords = $self->index_coords->[$grid_x + 3 * $grid_y];
		if (   $x > $coords->{x}
		    && $x < $coords->{x} + 120
		    && $y > $coords->{y}
		    && $y < $coords->{y} + 120) {
		    return $grid_x + 3 * $grid_y;
		}
	    }
	}
	return -1; # no index was found
    }

=head2 remove_piece

Remove the piece from the grid and return information about it.

=cut
    method remove_piece($piece_number) {
	my $current_piece = {
	    from_grid => $self,
	    piece => $self->pieces->[$piece_number],
	    old_position => $piece_number,
	};

	# Remove it from the grid
	$self->pieces->[$piece_number] = undef;

	return $current_piece;
    }

=head 2 insert_piece

Inserts a piece into the grid at the given index.
If a piece exists already at that position, that piece will
be returned. Otherwise, undef.

=cut
    method insert_piece($piece, $grid_index) {
	$piece->x($self->index_coords->[$grid_index]{x});
	$piece->y($self->index_coords->[$grid_index]{y});

	my $old_piece = $self->pieces->[$grid_index];
	$self->pieces->[$grid_index] = $piece;

	return $old_piece;
    }

=head2 get_overlap

Returns a hashref of all the grid positions the current_piece
currently overlaps with. The part that overlaps no grid will
be returned as well.

=cut

    method get_overlap($piece) {
	# We know that the piece is 120 x 120.
	# At most four pieces can be overlapped, or two pieces and nothing
	# TODO: Actually implement this. Currently we just return the overlap as entirely the upper_left position.
	my $x = $piece->x;
	my $y = $piece->y;
	my ($grid_index, $overlap);
	if (($grid_index = $self->grid_index_at($x, $y)) != -1) {
	    $overlap = [
		{
		    grid => $self,
		    grid_index => $grid_index,
		    pixels => 120 * 120,
		}
	    ];
	}
	return $overlap;
    }

    method _build_index_coords() {
	my $index_coords = [];
	for my $y (0..2) {
	    for my $x (0..2) {
		my $index = $x + (3 * $y);

		$index_coords->[$index] = {
		    x => $self->x + 121 * $x,
		    y => $self->y + 121 * $y,
		};
	    }
	}
	return $index_coords;
    }

}
