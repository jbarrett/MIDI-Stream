use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: MIDI note class

package MIDI::Stream::Event::ProgramChange;
class MIDI::Stream::Event::ProgramChange :isa( MIDI::Stream::Event::Channel );

our $VERSION = 0.00;

field $program :reader;

ADJUST {
    $program = $self->message->[1];
}

1;
