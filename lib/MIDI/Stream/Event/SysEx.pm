use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: SysEx Event

class MIDI::Stream::Event::SysEx
    :isa( MIDI::Stream::Event ) {

    field $msg_str;
    field $msg :reader = [];

    method msg_str {
        $msg_str //= join '', map { chr } $msg->@*;
    }

    ADJUST {
        ( undef, $msg->@* ) = $self->message->@*;
        delete $msg->[ -1 ] if $msg->[ -1 ] == 0xf7;
        $self->_push_fields( 'msg' );
    }
}

1;
