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
    is(scalar @{$grid->pieces}, 0, 'pieces is empty');
}

sub piece_at_returns_negative_one_if_no_piece_at_coordinates : Tests {
    my $grid = Games::Tetravex::Grid->new(x => 100, y => 100);
    _initialize_pieces($grid);

    my $piece_number = $grid->piece_at(75, 75);
    is ($piece_number, -1, 'no piece was found outside of grid');
}

sub piece_at_returns_0_if_coordinates_at_first_piece : Tests {
    my $grid = Games::Tetravex::Grid->new(x => 100, y => 100);
    _initialize_pieces($grid);

    my $piece_number = $grid->piece_at(120, 120);
    is ($piece_number, 0, 'first piece in grid found');
}

sub piece_at_finds_piece_in_middle_of_grid : Tests {
    my $grid = Games::Tetravex::Grid->new(x => 100, y => 100);
    _initialize_pieces($grid);

    my $piece_number = $grid->piece_at(225, 225);
    is ($piece_number, 4, 'piece found in middle of grid');
}

sub remove_piece_sets_removed_piece_to_undef_in_grid : Tests {
    my $grid = Games::Tetravex::Grid->new(x => 100, y => 100);
    _initialize_pieces($grid);

    my $piece = $grid->remove_piece(0);
    ok(defined $piece, 'valid piece was returned');
    is($grid->pieces->[0], undef, '...and the piece is no longer in the grid');
}

sub get_overlap_returns_only_the_position_the_upper_left_of_the_piece_overlaps : Tests {
    my $grid = Games::Tetravex::Grid->new(x => 100, y => 100);
    _initialize_pieces($grid);
    my $overlap_piece = Games::Tetravex::Piece->new(
	x => 225,
	y => 225,
	value => [0, 1, 2, 3],
    );

    my $overlap = $grid->get_overlap($overlap_piece);
    is($overlap->[0]{grid_index}, 4, 'overlap is whatever the upper left corner is');
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
