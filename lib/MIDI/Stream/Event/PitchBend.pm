use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: MIDI channel event base class

class MIDI::Stream::Event::PitchBend
    :isa( MIDI::Stream::Event::Channel ) {
    use MIDI::Stream::Tables qw/ combine_bytes /;

    field $value :reader;

    ADJUST {
        $value = combine_bytes( $self->message->@[ 1, 2 ] ) - 8192;

        $self->_push_fields( 'value' );
    }
}

1;
