use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: Song Select Event

class MIDI::Stream::Event::SongSelect
    :isa( MIDI::Stream::Event ) {

    field $song :reader;

    ADJUST {
        $song = $self->message->[1];
    }
}

1;
