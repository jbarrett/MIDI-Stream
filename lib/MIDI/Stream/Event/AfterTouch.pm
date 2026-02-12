use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: Channel After Touch event class

=encoding UTF-8

=head1 DESCRIPTION

Class represeting a Channel After Touch event.

=cut

package MIDI::Stream::Event::AfterTouch;
class MIDI::Stream::Event::AfterTouch :isa( MIDI::Stream::Event::Channel );

our $VERSION = 0.00;

use MIDI::Stream::Tables qw/ combine_bytes /;

=head1 METHODS

All methods in L<MIDI::Stream::Event::Channel>, plus:

=head2 pressure

After touch pressure

=cut

field $pressure :reader;

ADJUST {
    $pressure = $self->message->[ 1 ];
}

1;
