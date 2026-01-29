use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: MIDI Control Change class

class MIDI::Stream::Event::ControlChange
    :isa( MIDI::Stream::Event::Channel ) {

    field $control :reader;
    field $value   :reader;

    ADJUST {
        $control = $self->message->[ 1 ];
        $value   = $self->message->[ 2 ];

        $self->_push_fields( qw/ control value / );
    }
}

1;
