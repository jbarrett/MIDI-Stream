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
        plain_status_byte split_bytes
    /;

    use namespace::autoclean;

    field $zero_index_channel  :param = 1;
    field $concat_multibyte    :param = 1;
    field $sysex_f0_terminates :param = 1;

    field $enable_14bit :param = 0;
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

        # Allow definition of multiple notes in note messages
        # $encoder->encode( [ note_on => 0, [ 67, 68, 69 ], [ 100, 70, 60 ] ] );
        # TODO: This sucks, improve it or lose it.
        if ( index( $event[0], 'note' ) == 0 && ref $event[2] eq 'ARRAY' ) {
            my @vel = ref $event[3] eq 'ARRAY'
                ? $event[3]->@*
                : ( $event[3] ) x $event[2]->@*;

            push @vel, ( $vel[-1] ) x ( $event[2]->@* - @vel )
                if $event[2]->@* > @vel;

            return join '', map { $self->encode( [ $event->@[ 0, 1 ], $_, shift @vel ] ) } $event[2]->@*;
        }

        if ( $event[0] eq 'pitch_bend' ) {
            splice @event, 2, 1, split_bytes( $event[2] );
        }

        if ( $event[0] eq 'sysex' || $event[0] eq 'sysex_str' ) {
            my $msg = chr( 0xf0 ) . $event[1];
            $msg .= substr( $event[1], -1 ) ne chr( 0xf7 )
                ? chr( 0xf7 )
                : '';
            return $msg;
        }

        if ( $event[0] eq 'sysex_arr' ) {
            push @event, 0xf7 unless $event[-1] == 0xf7;
        }

        my $event_name = shift @event;
        my $status = plain_status_byte( $event_name );
        if ( ! $status ) {
            carp "Ignoring unknown status : $event_name";
            return;
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
