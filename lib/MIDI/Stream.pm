use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: MIDI bytestream decoding and encoding

package MIDI::Stream;
class MIDI::Stream;

our $VERSION = 0.00;

1;

=encoding UTF-8

=head1 DESCRIPTION

MIDI::Stream includes a realtime MIDI bytestream
L<encoder|MIDI::Stream::Encoder> and L<decoder|MIDI::Stream::Decoder>.

The classes in this distribution are stateful and are designed so a single
instance serves a single MIDI port, or device, or bytestream. Attempting to
consume or generate multiple streams in a single instance could result in
partial message collision. running status confusion, or inaccurate tempo
measurement - there are no MIDI-merge facilities.

For turning midi bytestreams into usable events see L<MIDI::Stream::Decoder>.

For turning performance and system events into a MIDI bytes suitable for
passing to MIDI hardware and other MIDI software see L<MIDI::Stream::Encoder>.

=cut
