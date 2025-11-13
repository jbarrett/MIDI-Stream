use strict;
use warnings;
package MIDI::Stream::Event::AfterTouch;

# ABSTRACT: MIDI channel event base class

use v5.26;
use Feature::Compat::Class;

class MIDI::Stream::Event::AfterTouch
    :isa( MIDI::Stream::Event::Channel ) {
    use MIDI::Stream::Tables qw/ combine_bytes /;

    field $pressure :reader;

    ADJUST {
        $pressure = $self->message->[ 1 ];
    }

}

1;
