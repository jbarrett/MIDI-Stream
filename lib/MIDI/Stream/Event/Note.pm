use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: MIDI note class

package MIDI::Stream::Event::Note;
class MIDI::Stream::Event::Note :isa( MIDI::Stream::Event::Channel );

our $VERSION = 0.00;

field $note :reader;
field $velocity :reader;

ADJUST {
    $note = $self->message->[1];
    $velocity = $self->message->[2];
}

1;
