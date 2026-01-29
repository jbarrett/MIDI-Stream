use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: MIDI channel event base class

class MIDI::Stream::Event::Channel :isa( MIDI::Stream::Event ) {
    field $channel :reader;

    ADJUST {
        $channel = $self->message->[0] & 0x0f;

        $self->_push_fields( 'channel' );
    }
}

1;
