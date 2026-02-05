use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: MIDI channel event base class

package MIDI::Stream::Event::Channel;
class MIDI::Stream::Event::Channel :isa( MIDI::Stream::Event );

our $VERSION = 0.00;

field $channel :reader;

ADJUST {
    $channel = $self->message->[0] & 0x0f;
}

1;
