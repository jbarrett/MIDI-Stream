use strict;
use warnings;
package MIDI::Stream::Event::Channel;

# ABSTRACT: MIDI channel event base class

use v5.26;
use Feature::Compat::Class;

package MIDI::Stream::Event::Channel;

class MIDI::Stream::Event::Channel :isa( MIDI::Stream::Event ) {
    field $channel :reader;

    ADJUST {
        $channel = $self->message->[0] & 0x0f;
    }
}

1;
