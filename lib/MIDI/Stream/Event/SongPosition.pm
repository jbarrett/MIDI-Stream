use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: Song Position Pointer Event

class MIDI::Stream::Event::SongPosition
    :isa( MIDI::Stream::Event ) {
    use MIDI::Stream::Tables qw/ combine_bytes /;

    field $position :reader;

    ADJUST {
        $position = combine_bytes( $self->message->@[ 1, 2 ] );

        $self->_push_fields( 'position' );
    }
}

1;
