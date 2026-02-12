use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: Time Code Qtr. Frame event class

=encoding UTF-8

=head1 DESCRIPTION

Class representing a Time Code event.

=cut

package MIDI::Stream::Event::TimeCode;
class MIDI::Stream::Event::TimeCode :isa( MIDI::Stream::Event );

our $VERSION = 0.00;

=head1 METHODS

All methods in L<MIDI::Stream::Event>, plus:

=head2 byte

The original timecode byte

=head2 high

Timecode high nibble

=head2 low

Timecode low nibble

=cut

field $byte :reader;
field $high;
field $low;

method high {
    $high //= $byte & 0xf0 >> 5;
}

method low {
    $low //= $byte & 0x0f;
}

ADJUST {
    $byte = $self->message->[ 1 ];
}

1;
