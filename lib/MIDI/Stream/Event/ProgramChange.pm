use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: Program Change event class

=head1 DESCRIPTION

Class represeting a Program Change event.

=cut

package MIDI::Stream::Event::ProgramChange;
class MIDI::Stream::Event::ProgramChange :isa( MIDI::Stream::Event::Channel );

our $VERSION = 0.00;

=head1 METHODS

All methods in L<MIDI::Stream::Event::Channel>, plus:

=head2 program

Program number

=cut

field $program :reader;

ADJUST {
    $program = $self->message->[1];
}

1;
