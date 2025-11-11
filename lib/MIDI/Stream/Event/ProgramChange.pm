use strict;
use warnings;
package MIDI::Stream::Event::ProgramChange;

# ABSTRACT: MIDI note class

use v5.26;
use Feature::Compat::Class;

class MIDI::Stream::Event::ProgramChange
    :isa( MIDI::Stream::Event::Channel ) {

    field $program :reader;

    ADJUST {
        $program = $self->message->[1];
    }

    method TO_JSON {
        +{
            map { $_ => $self->$_ }
                qw/ name channel program /
        };
    }
}

1;
