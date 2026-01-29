use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: MIDI note class

class MIDI::Stream::Event::ProgramChange
    :isa( MIDI::Stream::Event::Channel ) {

    field $program :reader;

    ADJUST {
        $program = $self->message->[1];

        $self->_push_fields( 'program' );
    }
}

1;
