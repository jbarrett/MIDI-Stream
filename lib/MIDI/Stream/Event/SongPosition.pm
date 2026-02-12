use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: Song Position event class

=encoding UTF-8

=head1 DESCRIPTION

Class represeting a Song Position Pointer event.

=cut

package MIDI::Stream::Event::SongPosition;
class MIDI::Stream::Event::SongPosition :isa( MIDI::Stream::Event );

our $VERSION = 0.00;

use MIDI::Stream::Tables qw/ combine_bytes /;

=head1 METHODS

All methods in L<MIDI::Stream::Event>, plus:

=head2 position

Position value - between 0 and 16383

=cut

field $position :reader;

ADJUST {
    $position = combine_bytes( $self->message->@[ 1, 2 ] );
}

1;
