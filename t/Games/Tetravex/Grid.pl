package Test::Games::Tetravex::Grid;

use Test::Most;
use parent 'Test::Class';

sub class { 'Games::Tetravex::Grid' }

sub startup : Tests(startup) {
    my $test = shift;
    my $class = $test->class;
    eval "use $class";
    die $@ if $@;
}

my $test;
my $class;

sub setup : Tests(setup) {
    $test = shift;
    $class = $test->class;
}

sub can_create_instance : Tests {
    can_ok($class, 'new');
    my $grid = $class->new(value => 8, x => 100, y => 100);
    isa_ok ($grid, $class, 'the newly created object is a Grid');
}

Test::Class->runtests;
