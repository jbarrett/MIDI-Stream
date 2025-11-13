use strict;
use warnings;
package MIDI::Stream::Event::PolyTouch;

# ABSTRACT: MIDI channel event base class

use v5.26;
use Feature::Compat::Class;

class MIDI::Stream::Event::PolyTouch
    :isa( MIDI::Stream::Event::Channel ) {

    field $note     :reader;
    field $pressure :reader;

    ADJUST {
        $note = $self->message->[ 1 ];
        $pressure = $self->message->[ 2 ];
    }
}

1;
