use strict;
use warnings;
package MIDI::Stream;

# ABSTRACT: MIDI bytestream decoding and encoding

use v5.26;
our @CARP_NOT = (__PACKAGE__);

use Feature::Compat::Class;

class MIDI::Stream {
    use MIDI::Stream::Tables ();

    method continue { MIDI::Stream::Tables::continue() }
    method stop { MIDI::Stream::Tables::stop() }

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Stream - MIDI bytestream decoding and encoding

=head1 VERSION

version 0.00

=head1 DESCRIPTION



=cut

