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

package Test::Games::Tetravex::Move;

use strict;
use warnings;

use Test::More;
use parent 'Test::Class';

my $font;

sub startup : Tests(startup) {
    eval "use Games::Tetravex::Move";
    die $@ if $@;
}

sub can_create_instance : Tests {
    can_ok('Games::Tetravex::Move', 'new');
    my $move = Games::Tetravex::Move->new();
    isa_ok ($move, 'Games::Tetravex::Move', 'the newly created object is a Move');
}

sub is_valid_returns_true_for_move_to_middle_with_no_neighbors : Tests {
    my ($from_grid, $to_grid) = _initialize_grids();
    my $piece = _create_piece(0, 1, 2, 3);
    
    my $move = Games::Tetravex::Move->new(
	from_grid  => $from_grid,
	to_grid    => $to_grid,
	from_index => 0,
	to_index   => 4,
	piece      => $piece,
    );

    ok($move->is_valid, 'the move was valid');
}

sub is_valid_returns_false_if_above_neighbor_number_does_not_match : Tests {
    my ($from_grid, $to_grid) = _initialize_grids();
    my $moved_piece =       _create_piece(0, 1, 2, 3); # 0
    $to_grid->pieces->[1] = _create_piece(2, 3, 3, 1); # 3
    
    my $move = Games::Tetravex::Move->new(
	from_grid  => $from_grid,
	to_grid    => $to_grid,
	from_index => 0,
	to_index   => 4,
	piece      => $moved_piece,
    );

    is($move->is_valid, 0, 'the move was not valid');
}

sub is_valid_returns_false_if_right_neighbor_number_does_not_match : Tests {
    my ($from_grid, $to_grid) = _initialize_grids();
    my $moved_piece =       _create_piece(1, 2, 1, 1); # 2
    $to_grid->pieces->[5] = _create_piece(1, 1, 1, 3); # 3
    
    my $move = Games::Tetravex::Move->new(
	from_grid  => $from_grid,
	to_grid    => $to_grid,
	from_index => 0,
	to_index   => 4,
	piece      => $moved_piece,
    );

    is($move->is_valid, 0, 'the move was not valid');
}

sub is_valid_returns_false_if_below_neighbor_number_does_not_match : Tests {
    my ($from_grid, $to_grid) = _initialize_grids();
    my $moved_piece =       _create_piece(3, 3, 0, 3); # 0
    $to_grid->pieces->[7] = _create_piece(2, 3, 3, 3); # 2
    
    my $move = Games::Tetravex::Move->new(
	from_grid  => $from_grid,
	to_grid    => $to_grid,
	from_index => 0,
	to_index   => 4,
	piece      => $moved_piece,
    );

    is($move->is_valid, 0, 'the move was not valid');
}

sub is_valid_returns_false_if_left_neighbor_number_does_not_match : Tests {
    my ($from_grid, $to_grid) = _initialize_grids();
    my $moved_piece =       _create_piece(3, 3, 3, 1); # 1
    $to_grid->pieces->[3] = _create_piece(3, 0, 3, 3); # 0
    
    my $move = Games::Tetravex::Move->new(
	from_grid  => $from_grid,
	to_grid    => $to_grid,
	from_index => 0,
	to_index   => 4,
	piece      => $moved_piece,
    );

    is($move->is_valid, 0, 'the move was not valid');
}

sub is_valid_returns_true_if_all_neighbors_match : Tests {
    my ($from_grid, $to_grid) = _initialize_grids();
    my $moved_piece =       _create_piece(1, 2, 3, 4);
    $to_grid->pieces->[1] = _create_piece(0, 0, 1, 0);
    $to_grid->pieces->[3] = _create_piece(0, 4, 0, 0);
    $to_grid->pieces->[5] = _create_piece(0, 0, 0, 2);
    $to_grid->pieces->[7] = _create_piece(3, 0, 0, 0);

    my $move = Games::Tetravex::Move->new(
	from_grid  => $from_grid,
	to_grid    => $to_grid,
	from_index => 0,
	to_index   => 4,
	piece      => $moved_piece,
    );

    is($move->is_valid, 1, 'the move was valid');
}

sub is_valid_returns_true_for_valid_move_to_upper_left_corner : Tests {
    my ($from_grid, $to_grid) = _initialize_grids();
    my $moved_piece =       _create_piece(1, 2, 3, 4);
    $to_grid->pieces->[1] = _create_piece(0, 0, 0, 2);
    $to_grid->pieces->[3] = _create_piece(3, 0, 0, 0);

    my $move = Games::Tetravex::Move->new(
	from_grid  => $from_grid,
	to_grid    => $to_grid,
	from_index => 0,
	to_index   => 0,
	piece      => $moved_piece,
    );

    is($move->is_valid, 1, 'the move was valid');
}

sub is_valid_returns_true_for_valid_move_to_upper_right_corner : Tests {
    my ($from_grid, $to_grid) = _initialize_grids();
    my $moved_piece =       _create_piece(1, 2, 3, 4);
    $to_grid->pieces->[1] = _create_piece(0, 4, 0, 0);
    $to_grid->pieces->[5] = _create_piece(3, 0, 0, 0);

    my $move = Games::Tetravex::Move->new(
	from_grid  => $from_grid,
	to_grid    => $to_grid,
	from_index => 0,
	to_index   => 2,
	piece      => $moved_piece,
    );

    is($move->is_valid, 1, 'the move was valid');
}

sub is_valid_returns_true_for_valid_move_to_bottom_left_corner : Tests {
    my ($from_grid, $to_grid) = _initialize_grids();
    my $moved_piece =       _create_piece(1, 2, 3, 4);
    $to_grid->pieces->[3] = _create_piece(0, 0, 1, 0);
    $to_grid->pieces->[7] = _create_piece(0, 0, 0, 2);

    my $move = Games::Tetravex::Move->new(
	from_grid  => $from_grid,
	to_grid    => $to_grid,
	from_index => 0,
	to_index   => 6,
	piece      => $moved_piece,
    );

    is($move->is_valid, 1, 'the move was valid');
}

sub is_valid_returns_true_for_valid_move_to_bottom_right_corner : Tests {
    my ($from_grid, $to_grid) = _initialize_grids();
    my $moved_piece =       _create_piece(1, 2, 3, 4);
    $to_grid->pieces->[5] = _create_piece(0, 0, 1, 0);
    $to_grid->pieces->[7] = _create_piece(0, 4, 0, 0);

    my $move = Games::Tetravex::Move->new(
	from_grid  => $from_grid,
	to_grid    => $to_grid,
	from_index => 0,
	to_index   => 0,
	piece      => $moved_piece,
    );

    is($move->is_valid, 1, 'the move was valid');
}

sub _initialize_grids {
    my $from_grid = Games::Tetravex::Grid->new(x => 100, y => 100);
    my $to_grid = Games::Tetravex::Grid->new(x => 500, y => 100);
    return ($from_grid, $to_grid);
}

sub _create_piece {
    my @values = @_;

    # The x and y values are irrelevant for these tests, so
    # we will always set them to 100, 100
    return Games::Tetravex::Piece->new(
	x => 100,
	y => 100,
	value => \@values,
	font  => undef,
    );
}

Test::Class->runtests;
