use strict;
use warnings;
package MIDI::Stream::FIFO;

# ABSTRACT: Fixed Size FIFO/Queue for rolling averages

use v5.26;
use Feature::Compat::Class;

class MIDI::Stream::FIFO {
    use List::Util qw/ reduce /;
    use namespace::autoclean;

    field $length :param = 24;
    field $members = [];

    field $average;

    method add( $member ) {
        $average = undef;
        unshift $members->@*, $member;
        splice $members->@*, $length if $members->@* > $length;
    }

    method average {
        return 0 unless $members->@*;
        $average //= ( reduce { $a + $b } $members->@* ) / $members->@*;
    }
}

1;
