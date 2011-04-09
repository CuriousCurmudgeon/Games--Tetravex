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

package Test::Games::Tetravex;

use strict;
use warnings;

use Test::More;
use parent 'Test::Class';

use FindBin qw( $Bin );
use Path::Class;

sub startup : Tests(startup) {
    my $self = shift;

    eval "use Games::Tetravex";
    die $@ if $@;

    $self->{resources} = dir( $Bin, '../../resources' );
}

sub can_create_instance : Tests {
    my $self = shift;

    can_ok('Games::Tetravex', 'new');
    my $game = Games::Tetravex->new( assets => $self->{resources} );
    isa_ok ($game, 'Games::Tetravex', 'the newly created object is a Games::Tetravex');
}

sub is_solved_is_true_if_all_pieces_played : Tests {
    my $self = shift;
    my $game = Games::Tetravex->new( assets => $self->{resources} );
    
    # Move all the pieces from one grid to another. is_solved
    # doesn't check if the pieces are in valid positions. They
    # are assumed to already be validated. It only cares that
    # every piece has been played.
    for my $i (0..8) {
	$game->played_pieces_grid->pieces->[$i] = $game->available_pieces_grid->pieces->[$i]
    }

    ok($game->is_solved);
}



Test::Class->runtests;
