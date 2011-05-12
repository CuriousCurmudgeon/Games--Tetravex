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

package Test::Games::Tetravex::Piece;

use strict;
use warnings;
use FindBin qw( $Bin );
use Path::Class;
use lib "$Bin/lib";

use Test::More;
use parent 'Test::Class';

my $font;

sub startup : Tests(startup) {
    eval "use Games::Tetravex::Piece";
    die $@ if $@;

    my $resources = dir( $Bin, 'resources' );
    $font = $resources->file('piece_font.ttf');
}

sub can_create_instance : Tests {
    can_ok('Games::Tetravex::Piece', 'new');
    my $piece = Games::Tetravex::Piece->new(value => [0, 1, 2, 3], x => 100, y => 100, font => $font);
    isa_ok ($piece, 'Games::Tetravex::Piece', 'the newly created object is a Piece');
}

Test::Class->runtests;
