use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: MIDI Time Code Qtr. Frame Event

package MIDI::Stream::Event::TimeCode;
class MIDI::Stream::Event::TimeCode :isa( MIDI::Stream::Event );

our $VERSION = 0.00;

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
