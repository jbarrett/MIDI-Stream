use strict;
use warnings;
package MIDI::Stream::Encoder;

# ABSTRACT: MIDI event to bytestream encoder

use v5.26;
our @CARP_NOT = (__PACKAGE__);

use Feature::Compat::Class;

class MIDI::Stream::Encoder :isa( MIDI::Stream ) {
    use Time::HiRes qw/ gettimeofday tv_interval /;
    use Carp qw/ carp croak /;
    use List::Util qw/ mesh /;
    use MIDI::Stream::Tables qw/
        status_byte has_channel keys_for is_single_byte plain_status_byte
    /;

    use namespace::autoclean;

    field $zero_index_channel  :param = 1;
    field $concat_multibyte    :param = 1;
    field $sysex_f0_terminates :param = 1;

    field $enable_14bit :param = 0;
    field $enable_rpn   :param = 0;
    field $enable_nrpn  :param = 0;
    field $enable_running_status :param = 1;

    field $running_status = 0;

    field $err_cb :param = sub { croak @_; };
    field $msg_cb :param = sub { @_ };

    field $warn_cb :param = sub { carp( @_ ); };

    method attach_callback( $callback ) {
        $msg_cb = $callback;
    }

    my method _flatten( $event ) {
        my @keys = ( 'name', keys_for( $event->{ name } )->@* );
        my @e = $event->@{ @keys };
        use DDP;  p @keys; p @e;
        [ $event->@{ @keys } ];
    }

    method _running_status( $status ) {
        # MIDI 1.0 Detailed Specification v4.2.1 p. 5
        # Data Types > Status Bytes > Running Status:
        # "Running Status will be stopped when any other Status byte
        # intervenes. Real-Time messages should not affect Running Status."
        #
        # There is at least one more single-byte status which is not realtime
        # (tune request), but also *probably* shouldn't touch running status -
        # Setting running status for a single byte status is redundant.
        #
        # I've decided to treat all single byte statuses as realtime for the
        # pruposes of running status. If tune request *should* effect the
        # running status, restore the is_realtime() line, and remove the
        # is_single_byte() line.
        #
        # return $status if is_realtime( $status );
        return $status if is_single_byte( $status );
        return 0 if $status == $running_status;
        $running_status = $status;
    }

    method encode( $event ) {
        $event = $self->&_flatten( $event )
            if ref $event eq 'HASH';
        my @event = $event->@*;

        my $status = plain_status_byte( shift @event );

        # 'Note off' events with velocity should retain their status,
        # and set running-status accordingly.
        # 'Note on' with velocity 0 is treated as 'Note off'.
        # Strings of 'Note on' events can take better advantage of
        # running-status.
        $status |= 0x10 if ( $status == 0x80 && !$event[ -1 ] );

        $status |= shift @event & 0xf if has_channel( $status );

        $status = $self->&_running_status( $status );

        join '', map { chr } $status
            ? ( $status, @event )
            : @event
    }

    method encode_events( @events ) {
        join '', map { $self->encode_event( $_ ) } @events;
    }
}

1;
