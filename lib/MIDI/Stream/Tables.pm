use strict;
use warnings;
package MIDI::Stream::Tables;

# ABSTRACT: MIDI 1.0 look up tables and utility functions

use parent 'Exporter';

my %status; my %fstatus;
BEGIN {
    %status = (
        note_off       => 0x80,
        note_on        => 0x90,
        polytouch      => 0xa0,
        control_change => 0xb0,
        program_change => 0xc0,
        aftertouch     => 0xd0,
        pitch_bend     => 0xe0,
    );

    %fstatus = (
        sysex          => 0xf0,
        timecode       => 0xf1,
        song_position  => 0xf2,
        song_select    => 0xf3,
        tune_request   => 0xf6,
        eox            => 0xf7,
        clock          => 0xf8,
        start          => 0xfa,
        continue       => 0xfb,
        stop           => 0xfc,
        active_sensing => 0xfe,
        system_reset   => 0xff,
    );
}

my %name = reverse %status;
my %fname = reverse %fstatus;

# Not exactly ecstatic about this pattern, but an alternative has yet to
# occur to me. One alternative I thought about was having objects push their
# ordered keys to an array in the top-level class, but this means you need
# an object instance to get the ordering:
# $class->from_hashref( $event )->as_arrayref seemed a little perverse.
my $event_keys = {
    note_off       => [qw/ channel note velocity /],
    note_on        => [qw/ channel note velocity /],
    polytouch      => [qw/ channel note pressure /],
    control_change => [qw/ channel control value /],
    program_change => [qw/ channel program /],
    aftertouch     => [qw/ channel pressure /],
    pitch_bend     => [qw/ channel value /],
    song_position  => [qw/ position /],
    song_select    => [qw/ song /],
    timecode       => [qw/ byte /],
    sysex          => [qw/ msg /],
};

sub keys_for {
    $event_keys->{ $_[0] } // [];
}

sub status_name {
    $name{ $_[0] & 0xf0 } // $fname{ $_[0] };
}

sub status_byte { $status{ $_[0] } // $fstatus{ $_[0] } }

sub is_realtime { $_[0] > 0xf7 }

sub is_single_byte { $_[0] > 0xf5 }

sub message_length {
    my ( $status ) = @_;

    return 0 unless $status;

    return 0 if $status < 0x80;
    return 3 if $status < 0xc0;
    return 2 if $status < 0xe0;
    return 3 if $status < 0xf0;

    return 0 if $status == 0xf0;
    return 2 if $status == 0xf1;
    return 3 if $status == 0xf2;
    return 2 if $status == 0xf3;

    return 1 if $status > 0xf5;
}

sub is_status_byte { $_[0] & 0x80 }

sub has_channel { $_[0] < 0xf0 }

sub is_cc {
    ( $_[0] & 0xf0 ) == 0xb0;
}

sub is_pitch_bend {
    ( $_[0] & 0xf0 ) == 0xe0;
}

sub combine_bytes {
    my ( $lsb, $msb ) = @_;
    $msb << 7 | $lsb & 0x7f;
}

sub split_bytes {
    my ( $value ) = @_;
    ( $value & 0x7f, $value >> 7 & 0x7f );
}

use constant {
    map { $_ => $_ } ( keys %fstatus, keys %status )
};

our @EXPORT_OK = qw/
    keys_for
    status_name
    status_byte
    status_chr
    is_realtime
    is_single_byte
    message_length
    is_status_byte
    has_channel
    is_cc
    is_pitch_bend
    combine_bytes
    split_bytes
/;
push @EXPORT_OK, keys %status, keys %fstatus;
our %EXPORT_TAGS = ( all => \@EXPORT_OK );
