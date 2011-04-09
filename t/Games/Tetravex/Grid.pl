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

package Test::Games::Tetravex::Grid;

use strict;
use warnings;
use FindBin qw( $Bin );
use Path::Class;
use lib "$Bin/lib";

use Games::Tetravex::Piece;
use Test::More;
use parent 'Test::Class';

my $font;

sub startup : Tests(startup) {
    eval "use Games::Tetravex::Grid";
    die $@ if $@;

    my $resources = dir( $Bin, 'resources' );
    $font = $resources->file('piece_font.ttf');
}

sub pieces_is_empty_by_default : Tests {
    my $grid = Games::Tetravex::Grid->new(x => 100, y => 100);
    is(scalar @{$grid->pieces}, 9, 'grid has 9 elements');
}

sub grid_index_at_returns_negative_one_if_no_piece_at_coordinates : Tests {
    my $grid = Games::Tetravex::Grid->new(x => 100, y => 100);
    _initialize_pieces($grid);

    my $grid_index = $grid->grid_index_at(75, 75);
    is ($grid_index, -1, 'no grid index was found outside of grid');
}

sub grid_index_at_returns_0_if_coordinates_at_first_piece : Tests {
    my $grid = Games::Tetravex::Grid->new(x => 100, y => 100);
    _initialize_pieces($grid);

    my $grid_index = $grid->grid_index_at(120, 120);
    is ($grid_index, 0, 'first position in grid found');
}

sub grid_index_at_finds_piece_in_middle_of_grid : Tests {
    my $grid = Games::Tetravex::Grid->new(x => 100, y => 100);
    _initialize_pieces($grid);

    my $grid_index = $grid->grid_index_at(225, 225);
    is ($grid_index, 4, 'position found in middle of grid');
}

sub grid_index_at_finds_piece_in_lower_right : Tests {
    my $grid = Games::Tetravex::Grid->new(x => 60, y => 60);
    _initialize_pieces($grid);

    my $grid_index = $grid->grid_index_at(339, 333);
    is ($grid_index, 8, 'position found in lower right of grid');
}

sub remove_piece_sets_removed_piece_to_undef_in_grid : Tests {
    my $grid = Games::Tetravex::Grid->new(x => 100, y => 100);
    _initialize_pieces($grid);

    my $piece = $grid->remove_piece(0);
    ok(defined $piece, 'valid piece was returned');
    is($grid->pieces->[0], undef, '...and the piece is no longer in the grid');
}

sub insert_piece_sets_coordinates_of_inserted_piece_to_new_postion : Tests {
    my $grid = Games::Tetravex::Grid->new(x => 100, y => 100);
    my $piece = Games::Tetravex::Piece->new(
	x => 0,
	y => 0,
	value => [0, 1, 2, 3],
	font  => undef,
    );

    my $old_piece = $grid->insert_piece($piece, 1);
    is($piece->x, 221, 'inserted piece x coord set correctly');
    is($piece->y, 100, 'inserted piece y coord set correctly');
    is($old_piece, undef, 'no old piece returned');
}

sub insert_piece_returns_old_piece_if_one_was_already_at_index : Tests {
    my $grid = Games::Tetravex::Grid->new(x => 100, y => 100);
    my $original_piece = Games::Tetravex::Piece->new(
	x => 0,
	y => 0,
	value => [0, 1, 2, 3],
	font  => undef,
    );
    $grid->insert_piece($original_piece, 0);

    my $piece = Games::Tetravex::Piece->new(
	x => 0,
	y => 0,
	value => [0, 1, 2, 3],
	font  => undef,
    );

    my $old_piece = $grid->insert_piece($piece, 0);
    is($old_piece, $original_piece, 'the piece already there was returned');
}

sub get_overlap_returns_only_the_position_the_upper_left_of_the_piece_overlaps : Tests {
    my $grid = Games::Tetravex::Grid->new(x => 100, y => 100);
    _initialize_pieces($grid);
    my $overlap_piece = Games::Tetravex::Piece->new(
	x     => 225,
	y     => 225,
	value => [0, 1, 2, 3],
	font  => $font,
    );

    my $overlap = $grid->get_overlap($overlap_piece);
    is($overlap->[0]{grid_index}, 4, 'overlap is whatever the upper left corner is');
}

sub get_overlap_returns_overlap_if_coordinates_are_in_grid : Tests {
    my $grid = Games::Tetravex::Grid->new(x => 60, y => 60);
    _initialize_pieces($grid);

    my $overlap_piece = Games::Tetravex::Piece->new(
	x => 326,
	y => 332,
	value => [0, 1, 2, 3],
	font  => $font,
    );
    my $overlap = $grid->get_overlap($overlap_piece);
    is($overlap->[0]{grid_index}, 8, 'overlap found in lower right corner of gri');
}

sub _initialize_pieces {
    my $grid = shift;

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
}

Test::Class->runtests;
