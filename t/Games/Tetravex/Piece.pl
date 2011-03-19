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
    my $piece = Games::Tetravex::Piece->new(value => [0, 1, 2, 3], x => 100, y => 100, $font);
    isa_ok ($piece, 'Games::Tetravex::Piece', 'the newly created object is a Piece');
}

Test::Class->runtests;
