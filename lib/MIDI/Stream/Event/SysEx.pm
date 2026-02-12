use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: SysEx event class

package MIDI::Stream::Event::SysEx;
class MIDI::Stream::Event::SysEx :isa( MIDI::Stream::Event );

=encoding UTF-8

=head1 DESCRIPTION

Class representing a SysEx message.

=cut

our $VERSION = 0.00;

=head1 METHODS

All methods in L<MIDI::Stream::Event>, plus:

=head2 msg

The original message as a MIDI byte array

=head2 msg_str

The original message as a MIDI byte string

=cut

field $msg_str;
field $msg :reader = [];

method msg_str {
    $msg_str //= join '', map { chr } $msg->@*;
}

ADJUST {
    ( undef, $msg->@* ) = $self->message->@*;
    delete $msg->[ -1 ] if $msg->[ -1 ] == 0xf7;
}

1;
