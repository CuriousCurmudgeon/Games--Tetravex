#!/usr/bin/perl
use strict;
use warnings;
use FindBin qw( $Bin );
use Path::Class;
use lib "$Bin/lib";
use Games::Tetravex;

my $resources = dir( $Bin, 'resources' );
my $game = Games::Tetravex->new( assets => $resources );
$game->run();
