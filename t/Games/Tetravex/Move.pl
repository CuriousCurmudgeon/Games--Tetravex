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

Test::Class->runtests;
