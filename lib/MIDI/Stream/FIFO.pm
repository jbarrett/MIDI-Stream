use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: Fixed Size FIFO/Queue for rolling averages

package MIDI::Stream::FIFO;
class MIDI::Stream::FIFO;

our $VERSION = 0.00;

use List::Util qw/ reduce /;
use namespace::autoclean;

field $length :param = 24;
field $members = [];

field $average;

method add( $member ) {
    undef $average;
    unshift $members->@*, $member;
    splice $members->@*, $length if $members->@* > $length;
}

method average {
    return 0 unless $members->@*;
    $average //= ( reduce { $a + $b } $members->@* ) / $members->@*;
}

1;
