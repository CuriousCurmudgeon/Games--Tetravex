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
    use Games::Tetravex::Piece;
    use SDL;
    use SDL::Event;
    use SDLx::App;
    use SDLx::Rect;

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
    
    has 'assets' => (
	is => 'ro',
	required => 1,
    );

    # from_grid = The grid the user moved the piece from (HASHREF)
    # piece = The piece actually being moved
    # old_position = The position in the grid it was moved from. (SCALAR)
    # old_x = The x position the piece was moved from
    # old_y = The y position the piece was moved from
    has 'current_piece' => (
	is => 'rw',
	init_arg => undef,
    );

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

	my %objects = (
	    app                   => $app,
	    available_pieces_grid => $available_pieces_grid,
	    played_pieces_grid    => $played_pieces_grid,
	    assets                => $assets,
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
	
    	    # Did they click a piece? If so, set it to be the current piece.
	    my $piece_info = $self->_is_piece_at($x, $y);
	    if (defined $piece_info) {
		$self->_set_current_piece($piece_info->{grid}, $piece_info->{grid_index}, $x, $y);
	    }

    	} elsif ($event->type == SDL_MOUSEBUTTONUP and $event->button_button == SDL_BUTTON_LEFT) {
    	    # Put the piece back in the grid if we have one
    	    $self->_drop_current_piece($event->motion_x, $event->motion_y) if (defined $self->current_piece);
    	} elsif ($event->type == SDL_MOUSEMOTION and defined $self->current_piece) {
    	    $self->current_piece->{piece}->x($event->motion_x);
    	    $self->current_piece->{piece}->y($event->motion_y);
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
    	if (defined $self->current_piece) {
    	    $self->current_piece->{piece}->draw($app);
    	}

    	$app->update;
    };

    method _populate_available_pieces($font) {
    	for my $y (0..2) {
    	    for my $x (0..2) {
    		my $index = $x + (3 * $y);
    		my $x_offset = $self->available_pieces_grid->x + 121 * $x;
    		my $y_offset = $self->available_pieces_grid->y + 121 * $y;

    		# TODO: This could theoretically produce a 10.
    		my @values = map { int(rand(10)) } (0..3);
    		$self->available_pieces_grid->pieces->[$index] = Games::Tetravex::Piece->new(
    		    x => $x_offset,
    		    y => $y_offset,
    		    value => \@values,
    		    font  => $font,
    		);

    	    }
    	}
    };

    method _set_current_piece($grid, $piece_number, $x, $y) {	
	my $removed_info = $grid->remove_piece($piece_number);

	$self->current_piece({});
	$self->current_piece->{from_grid} = $removed_info->{removed_grid};
	$self->current_piece->{old_position} = $removed_info->{old_position};
    	$self->current_piece->{piece} = $removed_info->{piece};

    	# Save the old coordinates of the piece before replacing them.
    	$self->current_piece->{old_x} = $self->current_piece->{piece}->x;
    	$self->current_piece->{old_y} = $self->current_piece->{piece}->y;
    	$self->current_piece->{piece}->x($x);
    	$self->current_piece->{piece}->y($y);
    }

    # Gets a grid index of a piece and the grid it is from if their is one at the given coordinates.
    # Returns undef if there isn't one.
    method _is_piece_at($x, $y) {
	for my $grid ($self->played_pieces_grid, $self->available_pieces_grid){
	    my $grid_index = $grid->grid_index_at($x, $y);
	    if ($grid_index != -1 && defined $grid->pieces->[$grid_index]) {
		return { grid => $grid, grid_index => $grid_index};
	    }
	}
	return undef;
    }

    method _drop_current_piece($x, $y) {
	$self->current_piece->{piece}->x($x);
	$self->current_piece->{piece}->y($y);

	# Get the overlap from each grid
	my $available_overlap = $self->available_pieces_grid->get_overlap($self->current_piece->{piece});
	my $played_overlap = $self->played_pieces_grid->get_overlap($self->current_piece->{piece});
		
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
		
	$self->current_piece->{piece}->x($destination->{grid}->index_coords->[$destination->{grid_index}]{x});
	$self->current_piece->{piece}->y($destination->{grid}->index_coords->[$destination->{grid_index}]{y});
	$destination->{grid}->pieces->[$destination->{grid_index}] = $self->current_piece->{piece};
	$self->current_piece(undef);
    }

}
