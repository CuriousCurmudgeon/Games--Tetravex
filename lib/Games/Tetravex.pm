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

class Games::Tetravex {
    use Games::Tetravex::Grid;
    use Games::Tetravex::Move;
    use Games::Tetravex::Piece;
    use List::Util 'shuffle';
    use SDL;
    use SDL::Event;
    use SDLx::App;
    use SDLx::Rect;
    use SDLx::Text;

    has 'app' => (
	is       => 'ro',
	isa      => 'SDLx::App',
	required => 1,
	handles  => [qw ( run )],
    );

    has 'available_pieces_grid' => (
	is       => 'ro',
	isa      => 'Games::Tetravex::Grid',
	required => 1,
    );
    
    has 'played_pieces_grid' => (
	is       => 'ro',
	isa      => 'Games::Tetravex::Grid',
	required => 1,
    );
    
    has 'moves' => (
	is       => 'ro',
	isa      => 'ArrayRef[Games::Tetravex::Move]',
	required => 1,
    );

    has 'is_moving_piece' => (
    	is      => 'rw',
    	isa     => 'Bool',
    	default => '0',
    );
    
    has 'assets' => (
	is       => 'ro',
	required => 1,
    );

    # The time the game was started
    has '_start_time' => (
	is      => 'ro',
	default => sub { return time;  },
    );

    has '_text' => (
	is       => 'ro',
	required => 1,
    );

    # # from_grid = The grid the user moved the piece from (HASHREF)
    # # piece = The piece actually being moved
    # # old_position = The position in the grid it was moved from. (SCALAR)
    # # old_x = The x position the piece was moved from
    # # old_y = The y position the piece was moved from
    # has 'current_piece' => (
    # 	is => 'rw',
    # 	init_arg => undef,
    # );

    sub BUILDARGS {
	my ($class, %args) = @_;
	
	my $app = SDLx::App->new(
	    w            => 900,
	    h            => 500,
	    t            => 'Tetravex',
	    exit_on_quit => 1,
	);
	
	my $assets = $args{assets};
	my $available_pieces_grid = Games::Tetravex::Grid->new(
	    x => 480,
	    y => 60,
	);
	my $played_pieces_grid = Games::Tetravex::Grid->new(
	    x => 60,
	    y => 60,
	);

	my $text = SDLx::Text->new( 
	    font    => $assets->file('piece_font.ttf')->absolute,
	    h_align => 'center',
	    color   => [255, 255, 255, 255],
	    x       => 0,
	    y       => 0,
	);

	my %objects = (
	    app                   => $app,
	    available_pieces_grid => $available_pieces_grid,
	    played_pieces_grid    => $played_pieces_grid,
	    assets                => $assets,
	    moves                 => [],
	    _text                 => $text,
	);

	return {%args, %objects};
    };

    method BUILD($args) {
	my $font = $self->assets->file('piece_font.ttf');
    	$self->_populate_available_pieces($font);
    	$self->app->add_event_handler( sub { $self->handle_mouse_click(@_) });
    	$self->app->add_show_handler( sub { $self->handle_show(@_) });
    }

    method handle_mouse_click($event, $app) {
    	# We want a drag & drop interface for pieces.
    	if ($event->type == SDL_MOUSEBUTTONDOWN and $event->button_button == SDL_BUTTON_LEFT) {
    	    my $x = $event->button_x;
    	    my $y = $event->button_y;
	
	    $self->_start_move_if_piece($x, $y);
	    $self->is_moving_piece(1);

    	} elsif ($event->type == SDL_MOUSEBUTTONUP and $event->button_button == SDL_BUTTON_LEFT) {
    	    # Put the piece back in the grid if we have one
    	    $self->_finish_move($event->motion_x, $event->motion_y) if (defined $self->is_moving_piece);

	    if($self->is_solved()) {
		print "puzzle solved!\n";
		exit;
	    }
    	} elsif ($event->type == SDL_MOUSEMOTION and $self->is_moving_piece) {
	    my $move = $self->moves->[-1];
    	    $move->piece->x($event->motion_x);
    	    $move->piece->y($event->motion_y);
    	}
    };

    method handle_show($delta, $app) {
    	# first, we clear the screen
    	$app->draw_rect( [ 0, 0, $app->w, $app->h ], 0x000000 );

    	# Draw the two grids. The left one is playing grid.
    	# The right one holds pieces in reserve.
    	$self->played_pieces_grid->draw($app);
    	$self->available_pieces_grid->draw($app);

    	# Draw the piece being dragged
    	if ($self->is_moving_piece) {
    	    $self->moves->[-1]->piece->draw($app);
    	}

	$self->_text->write_to($app, (time - $self->_start_time).' ');

    	$app->update;
    };

    # All pieces are checked before insertion, so we can assume
    # that if every piece has been placed, the puzzle is solved.
    method is_solved() {
	for my $piece (@{$self->played_pieces_grid->pieces}) {
	    return 0 unless defined $piece;
	}
	return 1;
    }

    method _populate_available_pieces($font) {
	use Data::Dumper;
	# create some initial values for each piece.
	my @solved;
	for my $i (0..8) {
	    # TODO: This could theoretically produce a 10.
	    my @values = map { int(rand(10)) } (0..3);
	    $solved[$i] = \@values;
	}

	# Now massage those values into a valid puzzle.
	$solved[1]->[3] = $solved[0]->[1];
	$solved[2]->[3] = $solved[1]->[1];
	$solved[3]->[0] = $solved[0]->[2];
	$solved[4]->[3] = $solved[3]->[1];
	$solved[4]->[0] = $solved[1]->[2];
	$solved[5]->[3] = $solved[4]->[1];
	$solved[5]->[0] = $solved[2]->[2];
	$solved[6]->[0] = $solved[3]->[2];
	$solved[7]->[3] = $solved[6]->[1];
	$solved[7]->[0] = $solved[4]->[2];
	$solved[8]->[3] = $solved[7]->[1];
	$solved[8]->[0] = $solved[5]->[2];
	
	my @shuffled = shuffle @solved;

	my $pieces = $self->available_pieces_grid->pieces;
    	for my $y (0 ..2) {
    	    for my $x (0..2) {
    		my $index = $x + (3 * $y);
    		my $x_offset = $self->available_pieces_grid->x + 121 * $x;
    		my $y_offset = $self->available_pieces_grid->y + 121 * $y;

    		$pieces->[$index] = Games::Tetravex::Piece->new(
    		    x => $x_offset,
    		    y => $y_offset,
    		    value => $shuffled[$index],
    		    font  => $font,
    		);

    	    }
    	}
    };

    # Starts a move if a piece is at the given coordinates.
    method _start_move_if_piece($x, $y) {
	for my $grid ($self->played_pieces_grid, $self->available_pieces_grid){
	    my $grid_index = $grid->grid_index_at($x, $y);
	    if ($grid_index != -1 && defined $grid->pieces->[$grid_index]) {
		my $move = Games::Tetravex::Move->new(
		    from_grid  => $grid,
		    from_index => $grid_index,
		    piece      => $grid->pieces->[$grid_index],
		);
		push @{$self->moves}, $move;
		$grid->remove_piece($grid_index);
		$self->is_moving_piece(1);
	    }
	}
    }

    method _finish_move($x, $y) {
	my $move = $self->moves->[-1];
	$move->piece->x($x);
	$move->piece->y($y);

	# Get the overlap from each grid
	my $available_overlap = $self->available_pieces_grid->get_overlap($move->piece);
	my $played_overlap = $self->played_pieces_grid->get_overlap($move->piece);
		
	# The destination is the one with the most overlap
	my $available_value = (defined $available_overlap->[0])
	    ? $available_overlap->[0]{pixels}
		: 0;
	my $played_value = (defined $played_overlap->[0])
	    ? $played_overlap->[0]{pixels}
		: 0;
	my $destination = ($available_value > $played_value)
	    ? $available_overlap->[0]
		: $played_overlap->[0];

	if (!$destination) {
	    $move->from_grid->insert_piece($move->piece, $move->from_index);
	}
	else {
	    $move->to_grid($destination->{grid});
	    $move->to_index($destination->{grid_index});
	
	    if (   ($move->to_grid == $self->played_pieces_grid && $move->is_valid)
		|| ($move->to_grid == $self->available_pieces_grid) ) {
		my $old_piece = $move->to_grid->insert_piece($move->piece, $move->to_index);
		if ($old_piece) {
		    $move->from_grid->insert_piece($old_piece, $move->from_index);
		}
	    }
	    else {
		# just put the piece back where we found it.
		$move->from_grid->insert_piece($move->piece, $move->from_index);
	    }
	}

	$self->is_moving_piece(0);
    }

}
