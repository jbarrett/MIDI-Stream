use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: MIDI channel event base class

class MIDI::Stream::Event::AfterTouch
    :isa( MIDI::Stream::Event::Channel ) {
    use MIDI::Stream::Tables qw/ combine_bytes /;

    field $pressure :reader;

    ADJUST {
        $pressure = $self->message->[ 2 ];
    }

}

1;
