use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: Song Select Event

package MIDI::Stream::Event::SongSelect;
class MIDI::Stream::Event::SongSelect :isa( MIDI::Stream::Event );

our $VERSION = 0.00;

field $song :reader;

ADJUST {
    $song = $self->message->[1];
}

1;
