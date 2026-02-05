use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: MIDI event base class

use experimental qw/ signatures /;

package MIDI::Stream::Event;
class MIDI::Stream::Event;

our $VERSION = 0.00;

use Carp qw/ croak /;
use MIDI::Stream::Tables qw/ status_name keys_for /;
use namespace::autoclean;

field $name :reader;
field $message :reader :param;
field $bytes;
field $status :reader;

method bytes {
    $bytes //= join '', map { chr } $message->@*;
}

method as_hashref {
    +{
        map { $_ => $self->$_ }
            ( 'name', keys_for( $self->name )->@* )
    };
}

method TO_JSON { $self->as_hashref };

method as_arrayref {
    [
        $self->name =>
        map { $self->$_ } keys_for( $self->name )->@*
    ]
}

ADJUST {
    $name = status_name( $message->[0] ) // 'unknown';
    $status = $message->[0];
    # note on with velocity 0 is note off
    $name = 'note_off' if $status < 0xa0 && !$message->[2];
}

1;
