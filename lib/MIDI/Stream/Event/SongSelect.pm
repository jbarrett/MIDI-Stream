use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: Song Select event class

=encoding UTF-8

=head1 DESCRIPTION

Class representing a Song Position Pointer event.

=cut

package MIDI::Stream::Event::SongSelect;
class MIDI::Stream::Event::SongSelect :isa( MIDI::Stream::Event );

our $VERSION = 0.00;

=head1 METHODS

All methods in L<MIDI::Stream::Event>, plus:

=head2 song

Song number

=cut

field $song :reader;

ADJUST {
    $song = $self->message->[1];
}

1;
