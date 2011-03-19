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

class Games::Tetravex::Piece {
    use Carp 'cluck';
    use SDL::GFX::Primitives;
    use SDL::Surface;
    use SDLx::Text;
    use MooseX::ClassAttribute;

    # Colors are ROYGBIV, with black added to the front, and grey and white added
    # to the end.
    # The first element in each color is the actual color of the triangle.
    # The second element is the color text will appear on the triangle.
    class_has 'Colors' => (
	is      => 'ro',
	isa     => 'ArrayRef',
	default => sub { 
	    [
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
	];
	},
    );

    has 'value' => (
	is  => 'ro',
	isa => 'ArrayRef',
    );

    has ['x', 'y'] => (
	is  => 'rw',
	isa => 'Int',
    );

    has 'font' => (
	is       => 'ro',
	required => 1,
    );

    has '_black_text' => (
	is       => 'ro',
	lazy     => 1,
	builder  => '_build_black_text',
	init_arg => undef,
    );

    has '_white_text' => (
	is       => 'ro',
	lazy     => 1,
	builder  => '_build_white_text',
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

=head2 draw

Draws the given piece with its upper left corner at ($x_offset, $y_offset)

=cut
    method draw($surface) {
	my $x = $self->x;
	my $y = $self->y;
	$self->_draw_triangle( $surface, $self->top,
			       $x + 0,   $y + 0,
			       $x + 120, $y + 0,
			       $x + 60,  $y + 60
			   );

	$self->_draw_triangle( $surface, $self->right,
			       $x + 120, $y + 0,
			       $x + 120, $y + 120,
			       $x + 60,  $y + 60
			   );
	$self->_draw_triangle( $surface, $self->bottom,
			       $x + 120, $y + 120,
			       $x + 0,   $y + 120,
			       $x + 60,  $y + 60
			   );
	$self->_draw_triangle( $surface, $self->left,
			       $x + 0,  $y + 120,
			       $x + 0,  $y + 0,
			       $x + 60, $y + 60
			   );
    }

=head2 draw_triangle

Draws a triangle for a piece. Each triangle has a 1 px black border
and a number in the middle.

=cut

    method _draw_triangle($surface, $number, $x1, $y1, $x2, $y2, $x3, $y3) {
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
	return SDLx::Text->new( font => $self->font->absolute,
				h_align => 'center',
				color => [0, 0, 0, 255],
			    );
    }

    method _build_white_text {
	return SDLx::Text->new( font => $self->font->absolute,
				h_align => 'center',
				color => [255, 255, 255, 255],
			    );
    }
}
