use strict;
use warnings;
package MIDI::Stream::Event::Note;

# ABSTRACT: MIDI note class

use v5.26;
use Feature::Compat::Class;

package MIDI::Stream::Event::Note;

class MIDI::Stream::Event::Note
    :isa( MIDI::Stream::Event::Channel ) {

    field $note :reader;
    field $velocity :reader;

    ADJUST {
        $note = $self->message->[1];
        $velocity = $self->message->[2];
    }

}

1;
