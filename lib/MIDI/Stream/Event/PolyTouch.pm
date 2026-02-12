use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: Polyphonic After Touch event class

=encoding UTF-8

=head1 DESCRIPTION

Class represeting a Polyphonic After Touch event.

=cut

package MIDI::Stream::Event::PolyTouch;
class MIDI::Stream::Event::PolyTouch :isa( MIDI::Stream::Event::Channel );

our $VERSION = 0.00;

=head1 METHODS

All methods in L<MIDI::Stream::Event::Channel>, plus:

=head2 note

The note pressure is applied to

=head2 pressure

The aftertouch pressure for this note

=cut

field $note     :reader;
field $pressure :reader;

ADJUST {
    $note = $self->message->[ 1 ];
    $pressure = $self->message->[ 2 ];
}

1;
