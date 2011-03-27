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

class Games::Tetravex::Move {
    use Games::Tetravex::Grid;
    use Games::Tetravex::Piece;

    # The grids the piece is being moved between.
    has ['from_grid', 'to_grid'] => (
	is => 'rw',
    );

    # The position in the grids the piece was in and was moved to.
    has ['from_index', 'to_index'] => (
	is => 'rw',
    );

    # The piece actually being moved.
    has 'piece' => (
	is => 'rw',
    );

    # Is this move valid? This means that the colors/numbers
    # of all neighboring pieces match.
    method is_valid() {
	# Look at each neighboring position. If that position
	# is outside of the grid, then we don't care about it.
	my $to_index = $self->to_index;

	# Look above.
	if ( ($to_index - 3) >= 0 ) {
	    my $above = $self->to_grid->pieces->[$to_index - 3];
	    if (defined $above && $self->piece->top != $above->bottom ) {
		return 0;
	    }
	}
	# Look below
	if ( ($to_index + 3) <= 8 ) {
	    my $below = $self->to_grid->pieces->[$to_index + 3];
	    if (defined $below && $self->piece->bottom != $below->top ) {
		return 0;
	    }
	}
	# Look to the right
	if ( ($to_index % 3) != 2 ) {
	    my $right = $self->to_grid->pieces->[$to_index + 1];
	    if (defined $right && $self->piece->right != $right->left ) {
		return 0;
	    }
	}
	# Look to the left
	if ( ($to_index % 3) != 0 ) {
	    my $left = $self->to_grid->pieces->[$to_index - 1];
	    if (defined $left && $self->piece->left != $left->right ) {
		return 0;
	    }
	}

	return 1;
    }

}
