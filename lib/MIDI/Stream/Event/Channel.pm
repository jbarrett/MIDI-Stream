use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: MIDI channel event base class
#
=encoding UTF-8

=head1 DESCRIPTION

Channel message base class.

=cut

package MIDI::Stream::Event::Channel;
class MIDI::Stream::Event::Channel :isa( MIDI::Stream::Event );

our $VERSION = 0.00;

=head1 METHODS

All methods in L<MIDI::Stream::Event>, plus:

=head2 channel

Event channel.

=cut

field $channel :reader;

ADJUST {
    $channel = $self->message->[0] & 0x0f;
}

1;
