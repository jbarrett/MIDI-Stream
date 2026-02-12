use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: Note event class

=encoding UTF-8

=head1 DESCRIPTION

Class represeting a Note On or Note Off event.

=cut

package MIDI::Stream::Event::Note;
class MIDI::Stream::Event::Note :isa( MIDI::Stream::Event::Channel );

our $VERSION = 0.00;

=head1 METHODS

All methods in L<MIDI::Stream::Event::Channel>, plus:

=head2 note

The played or released note.

=head2 velocity

The play or release velocity.

=cut

field $note :reader;
field $velocity :reader;

ADJUST {
    $note = $self->message->[1];
    $velocity = $self->message->[2];
}

1;
