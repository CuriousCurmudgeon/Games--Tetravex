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

use Moose;
use MooseX::Declare;
use SDL::GFX::Primitives;
use SDL::Surface;
use SDLx::Text;

class Games::Tetravex::Piece {

    use MooseX::ClassAttribute; #Because of how MooseX::Declare works, this seems to need to be inside of the class declaration.

    # Colors are ROYGBIV, with black added to the front, and grey and white added
    # to the end.
    # The first element in each color is the actual color of the triangle.
    # The second element is the color text will appear on the triangle.
    class_has 'Colors' => (
	is => 'ro',
	isa => 'ArrayRef',
	default => sub {
	    [0x000000FF, [255, 255, 255, 255]], # Black
	    [0xFF0000FF, [0, 0, 0, 255]], # Red
	    [0xF58D05FF, [0, 0, 0, 255]], # Orange
	    [0xFAFA1EFF, [0, 0, 0, 255]], # Yellow
  	    [0x00FF00FF, [0, 0, 0, 255]], # Green
	    [0x0000FFFF, [0, 0, 0, 255]], # Blue
	    [0x9205EBFF, [0, 0, 0, 255]], # Indigo
            [0xEE82EEFF, [0, 0, 0, 255]], # Violet
            [0xCFCFCFFF, [0, 0, 0, 255]], # Grey
            [0xFFFFFFFF, [0, 0, 0, 255]], # White
	},
    );

    has 'value' => (
	is => 'ro',
	isa => 'ArrayRef[Scalar]',
    );

    has ['x', 'y'] => (
	is => 'rw',
	isa => 'Int',
    );

    has '_black_text' => (
	is => 'ro',
	lazy => 1,
	builder => '_build_black_text',
	init_arg => undef,
    );

    has '_white_text' => (
	is => 'ro',
	lazy => 1,
	builder => '_build_white_text',
	init_arg => undef,
    );

    method top {
	return $self->value->[0];
    };

    method right {
	return $self->value->[1];
    };

    method bottom {
	return $self->value->[2];
    };
    
    method left {
	return $self->value->[3];
    };

=head2 draw_piece

Draws the given piece with its upper left corner at ($x_offset, $y_offset)

=cut
    method draw($surface) {
	$self->_draw_triangle( $surface, $self->top,
			       0, 0,
			       120, 0,
			       60, 60
			   );

	$self->_draw_triangle( $surface, $self->right,
			       120, 0,
			       120, 120,
			       60, 60
			   );
	$self->_draw_triangle( $surface, $self->bottom,
			       120, 120,
			       0, 120,
			       60, 60
			   );
	$self->_draw_triangle( $surface, $self->left,
			       0, 120,
			       0, 0,
			       60, 60
			   );
    }

=head2 draw_triangle

Draws a triangle for a piece. Each triangle has a 1 px black border
and a number in the middle.

=cut

    method _draw_triangle {
	my ($surface, $number, $x1, $y1, $x2, $y2, $x3, $y3) = @_;

	SDL::GFX::Primitives::filled_trigon_color( $surface,
						   $x1, $y1,
						   $x2, $y2 ,
						   $x3, $y3,
						   __PACKAGE__->Colors->[$number][0]
					       );
	SDL::GFX::Primitives::trigon_color( $surface,
					    $x1, $y1,
					    $x2, $y2,
					    $x3, $y3,
					    0x000000FF
					);

	# TODO: Fix the center point calculation. This is a quick hack.
	my $center_x = ($x1 + $x2 + $x3) / 3 - 5;
	my $center_y = ($y1 + $y2 + $y3) / 3 - 20;

	my $text_color = __PACKAGE__->Colors->[$number][1];
	if ($text_color->[0]) {
	    # TODO: The space after $number is preventing SDLx::Text
	    # from interpreting the value as 0, which causes an error.
	    $self->_white_text->write_xy( $surface, $center_x, $center_y, "$number ");
	} else {
	    $self->_black_text->write_xy( $surface, $center_x, $center_y, "$number");
	}
    };

    method _build_black_text {
	return SDLx::Text->new( font => '../../resources/Arial_Black.ttf',
				h_align => 'center',
				color => [0, 0, 0, 255],
			    );
    }

    method _build_white_text {
	return SDLx::Text->new( font => '../../resources/Arial_Black.ttf',
				h_align => 'center',
				color => [255, 255, 255, 255],
			    );
    }
}
