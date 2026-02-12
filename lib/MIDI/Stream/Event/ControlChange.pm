use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: Control Change event class

=encoding UTF-8

=head1 DESCRIPTION

Class representing a Control Change event.

=cut

package MIDI::Stream::Event::ControlChange;
class MIDI::Stream::Event::ControlChange :isa( MIDI::Stream::Event::Channel );

our $VERSION = 0.00;

use MIDI::Stream::Tables qw/ combine_bytes /;

=head1 METHODS

All methods in L<MIDI::Stream::Event::Channel>, plus:

=head2 control

The Continuous Controller (CC) the value should apply to.

=head2 value

The CC value.

=cut

field $control :reader;
field $value   :reader;

ADJUST {
    $control = $self->message->[ 1 ];
    $value   = $self->message->[ 2 ];
}

1;
