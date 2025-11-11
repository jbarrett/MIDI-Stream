use strict;
use warnings;
package MIDI::Stream::Event::ControlChange;

# ABSTRACT: MIDI Control Change class

use v5.26;
use Feature::Compat::Class;

class MIDI::Stream::Event::ControlChange
    :isa( MIDI::Stream::Event::Channel ) {
    use MIDI::Stream::Tables qw/ combine_bytes /;

    field $control :reader;
    field $value   :reader;

    ADJUST {
        $control = $self->message->[ 1 ];
        $value   = $self->message->[ 2 ];

    }

    method TO_JSON {
        +{
            map { $_ => $self->$_ }
                qw/ name channel control value /
        };
    }
}

1;
