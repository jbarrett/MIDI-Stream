use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: MIDI channel event base class

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
