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

}
