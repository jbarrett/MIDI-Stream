use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: MIDI event to bytestream encoder

class MIDI::Stream::Encoder :isa( MIDI::Stream ) {
    use Time::HiRes qw/ gettimeofday tv_interval /;
    use Carp qw/ carp croak /;
    use List::Util qw/ mesh /;
    use MIDI::Stream::Tables qw/
        status_byte has_channel keys_for is_single_byte
        plain_status_byte split_bytes is_realtime
    /;

    use namespace::autoclean;

    field $zero_index_channel  :param = 1;
    field $concat_multibyte    :param = 1;
    field $sysex_f0_terminates :param = 1;

    field $enable_14bit :param = 0;
    field $enable_running_status :param = 0;
    field $running_status_retransmit :param = 10;

    field @msb;
    field $running_status = 0;
    field $running_status_count = 0;

    my method _flatten( $event ) {
        my @keys = ( 'name', keys_for( $event->{ name } )->@* );
        my @e = $event->@{ @keys };
        [ $event->@{ @keys } ];
    }

    method _running_status( $status ) {
        return $status unless $enable_running_status;
        # MIDI 1.0 Detailed Specification v4.2.1 p. 5
        # Data Types > Status Bytes > Running Status:
        #
        # "For Voice and Mode messages only ...
        # Running Status will be stopped when any other Status byte
        # intervenes. Real-Time messages should not affect Running Status."
        #
        # I interpret this as:
        # - Running status is only for channel messages
        # - System messages reset status, but do not set it
        # - ...apart form realtime status which does not reset or set
        return $status if is_realtime( $status );
        if ( ! has_channel( $status ) ) {
            $self->clear_running_status;
            return $status;
        }

        # Running status found, and haven't reached retransmit threshold
        return 0 if
            $status == $running_status &&
            $running_status_count++ < $running_status_retransmit;

        # Set and return status
        $running_status_count = 0;
        $running_status = $status;
    }

    method clear_running_status {
        $running_status_count = 0;
        $running_status = 0;
    }

    method encode( $event ) {
        $event = $self->&_flatten( $event )
            if ref $event eq 'HASH';
        $event = $event->as_arrayref
            if eval{ $event->isa('MIDI::Stream::Event') };
        my @event = $event->@*;

        if ( $event[0] eq 'sysex' ) {
            if ( ref $event[1] eq 'ARRAY' ) {
                @event = ( $event[0], $event[1]->@* );
                push @event, 0xf7 unless $event[-1] == 0xf7;
            }
            else {
                my $msg = chr( 0xf0 ) . $event[1];
                $msg .= substr( $event[1], -1 ) ne chr( 0xf7 )
                    ? chr( 0xf7 )
                    : '';
                return $msg;
            }
        }

        if ( $enable_14bit && $event[0] eq 'control_change' && $event[2] < 0x20 ) {
            my ( $lsb, $msb ) = split_bytes( $event [3] );
            # Comparing new MSB against last-sent MSB for this CC
            if ( $msb[ $event[2] ] == $msb ) {
                # MSB already sent, just send LSB on CC + 32
                $event[2] |= 0x20;
                $event[3] = $lsb;
            }
            else {
                # Re-send MSB, concatenate LSB running status
                $msb[ $event[2] ] = $msb;
                $event[3] = $msb;
                push @event, $event[2] | 0x20, $lsb;
            }
        }

        my $event_name = shift @event;
        my $status = plain_status_byte( $event_name );
        if ( ! $status ) {
            carp "Ignoring unknown status : $event_name";
            return;
        }

        if ( $event_name eq 'pitch_bend' ) {
            splice @event, 1, 1, split_bytes( $event[2] + 8192 );
        }

        # 'Note off' events with velocity should retain their status,
        # and set running-status accordingly.
        # 'Note on' with velocity 0 is treated as 'Note off'.
        # Strings of 'Note on' events can take better advantage of
        # running-status.
        # TODO: Should the status be changed if the current running
        # status is 0x8n?
        $status |= 0x10 if ( $status == 0x80 && !$event[ -1 ] );

        $status |= shift @event & 0xf if has_channel( $status );

        $status = $self->&_running_status( $status );
        join '', map { chr } $status
            ? ( $status, @event )
            : @event
    }

    method encode_events( @events ) {
        join '', map { $self->encode( $_ ) } @events;
    }
}

1;
