use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: MIDI channel event base class

package MIDI::Stream::Event::AfterTouch;
class MIDI::Stream::Event::AfterTouch :isa( MIDI::Stream::Event::Channel );

our $VERSION = 0.00;

use MIDI::Stream::Tables qw/ combine_bytes /;

field $pressure :reader;

ADJUST {
    $pressure = $self->message->[ 1 ];
}

1;
