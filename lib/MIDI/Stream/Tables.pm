use strict;
use warnings;
package MIDI::Stream::Tables;

# ABSTRACT: MIDI 1.0 message type and other look up tables.

use parent 'Exporter';

use List::Util qw/ first /;
use Scalar::Util qw/ looks_like_number /;

my %status = (
    note_off            => 0x80,
    note_on             => 0x90,
    key_after_touch     => 0xa0,
    control_change      => 0xb0,
    patch_change        => 0xc0,
    channel_after_touch => 0xd0,
    pitch_wheel_change  => 0xe0,
);

my %name = reverse %status;

my %fstatus = (
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

my %fname = reverse %fstatus;

sub status_name {
    $name{ $_[0] & 0xf0 } // $fname{ $_[0] };
}

sub status_byte {
    my ( $status_name, $channel ) = @_;
    $channel //= 0;
    my $byte = $status{ $status_name } // $fstatus{ $status_name };
    $byte |= ( $channel & 0x0f ) if has_channel( $byte );
    $byte;
}

sub status_chr { chr status_byte( @_ ) }

sub is_realtime {
    my ( $status ) = @_;
    $status = status_name( $status ) if looks_like_number( $status );
    # is this really faster than the equivalent grep? Or a hash lookup?
    first { $status eq $_ } qw/ clock start stop continue /
}

# includes channel as a byte
sub message_length {
    my ( $status ) = @_;
    $status = status_byte( $status ) if !looks_like_number( $status );

    return 0 if $status < 0x80;
    return 4 if $status < 0xc0;
    return 3 if $status < 0xe0;
    return 4 if $status < 0xf0;

    return 0 if $status == 0xf0;
    return 2 if $status == 0xf1;
    return 3 if $status == 0xf2;
    return 2 if $status == 0xf3;

    return 1 if $status > 0xf5;
}

sub is_status_byte { $_[0] & 0x80 }
sub has_channel { $_[0] < 0xf0 }

our @EXPORT_OK = qw/
    status_name
    status_byte
    status_chr
    message_length
    is_status_byte
    has_channel
/;
our %EXPORT_TAGS = ( all => \@EXPORT_OK );
