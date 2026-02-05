use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: MIDI Control Change class

package MIDI::Stream::Event::ControlChange;
class MIDI::Stream::Event::ControlChange :isa( MIDI::Stream::Event::Channel );

our $VERSION = 0.00;

use MIDI::Stream::Tables qw/ combine_bytes /;

field $control :reader;
field $value   :reader;

ADJUST {
    $control = $self->message->[ 1 ];
    $value   = $self->message->[ 2 ];
}

1;
