use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: SysEx Event

package MIDI::Stream::Event::SysEx;
class MIDI::Stream::Event::SysEx :isa( MIDI::Stream::Event );

our $VERSION = 0.00;

field $msg_str;
field $msg :reader = [];

method msg_str {
    $msg_str //= join '', map { chr } $msg->@*;
}

ADJUST {
    ( undef, $msg->@* ) = $self->message->@*;
    delete $msg->[ -1 ] if $msg->[ -1 ] == 0xf7;
}

1;
