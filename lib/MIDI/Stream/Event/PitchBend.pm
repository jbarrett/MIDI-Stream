use strict;
use warnings;
package MIDI::Stream::Event::PitchBend;

# ABSTRACT: MIDI channel event base class

use v5.26;
use Feature::Compat::Class;

class MIDI::Stream::Event::PitchBend
    :isa( MIDI::Stream::Event::Channel ) {
    use MIDI::Stream::Tables qw/ combine_bytes /;

    field $value :reader;

    ADJUST {
        $value = combine_bytes( $self->message->@[ 2, 1 ] );
    }
}

1;
