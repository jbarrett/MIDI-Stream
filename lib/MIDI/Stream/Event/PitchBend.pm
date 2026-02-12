use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: Pitch Bend event class

=encoding UTF-8

=head1 DESCRIPTION

Class representing a Pitch Bend event.

=cut

package MIDI::Stream::Event::PitchBend;
class MIDI::Stream::Event::PitchBend :isa( MIDI::Stream::Event::Channel );

our $VERSION = 0.00;

use MIDI::Stream::Tables qw/ combine_bytes /;

=head1 METHODS

All methods in L<MIDI::Stream::Event::Channel>, plus:

=head2 value

The pitch bend value - between -8192 and 8191.

=cut

field $value :reader;

ADJUST {
    $value = combine_bytes( $self->message->@[ 1, 2 ] ) - 8192;
}

1;
