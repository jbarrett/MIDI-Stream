use strict;
use warnings;
package MIDI::Stream::Parser;

# ABSTRACT: MIDI bytestream parser

use v5.26;
our @CARP_NOT = (__PACKAGE__);

use Feature::Compat::Class;

class MIDI::Stream::Parser {
    use Scalar::Util qw/ reftype /;
    use Time::HiRes qw/ gettimeofday tv_interval /;
    use Carp qw/ carp croak /;
    use MIDI::Stream::Tables ':all';

    field $zero_index_channel  :param = 1;
    field $sysex_as_string     :param = 1;
    field $detect_note_off     :param = 1;
    field $retain_events       :param = 1;

    field $mode_14bit :param = 0;
    field $mode_rpn   :param = $mode_14bit;
    field $mode_nrpn  :param = $mode_14bit;

    field $error_cb :param = sub { croak @_; };
    field $event_cb :param = sub { @_ };
    field $filter_cb = {};

    field $name :param = 'midi_stream:' . gettimeofday;

    field @events;
    field @pending_event;
    field $events_queued = 0;


    method attach_callback( $event, $callback ) {
        if ( reftype $event eq 'ARRAY' ) {
            $self->attach_callback( $_, $callback ) for $event->@*;
            return;
        }
        push $filter_cb->{ $event }->@*, $callback;
    }

    method events {
        my @return_events = @events;
        @events = ();
        $events_queued = 0;
        @return_events;
    }

    # TODO: Lexical-scope-ise these when feature available

    method _push_event( $event = undef ) {
        state $t = [ gettimeofday ];
        $event //= [ @pending_event ];
        $events_queued = 1;

        # note on with velocity 0 is note off
        $event->[0] = 'note_off'
            if ( $detect_note_off && $event->[0] eq 'note_on' && $event->[3] == 0 );

        if ( $event->[0] eq 'sysex' && $sysex_as_string ) {
            $event = [
                sysex =>
                join '',
                map { chr } @pending_event[ 1 .. $#pending_event ]
            ];
        }

        push @events, $event if $retain_events;

        my $dt = tv_interval( $t );
        $t = [ gettimeofday ];

        my @callbacks = ( $filter_cb->{ all } // [] )->@*;
        push @callbacks, ( $filter_cb->{ $event->[0] } // [] )->@*;

        for my $cb ( @callbacks ) {
            last unless $cb->( $name, $dt, $event ) eq $self->continue;
        }

        $event_cb->( $event );
    }

    method parse( $bytestring ) {
        my @bytes = unpack 'C*', $bytestring;
        my $status;

        BYTE:
        while ( @bytes ) {

            # Status byte - start/end of message
            if ( is_status_byte( $bytes[0] ) ) {
                my $status = shift @bytes;
                my $status_name = status_name( $status );

                $self->throw( sprintf( "Unsupported status type: 0x%x", $status ) )
                    unless $status_name;

                # Real-Time messages can appear inside other messages.
                # Let's just propagate all one-byte statuses as if
                # they were realtime. This is out of spec, but doesn't
                # have any weird side-effects I can think of right now.
                # (Maybe it screws with running status?)
                if ( message_length( $status ) == 1 ) {
                    $self->_push_event( [ $status_name ] );
                    next BYTE;
                }

                # End-of-Xclusive
                if ( $status_name eq 'eox' ) {
                    $self->throw( "EOX received for non-SysEx message")
                        unless $pending_event[0] eq 'sysex';
                    $self->_push_event;
                    @pending_event = ();
                    next BYTE;
                }

                # Any non-Real-Time status byte ends a SysEx
                # Push the sysex and proceed ...
                if ( $pending_event[0] eq 'sysex' ) {
                    $self->_push_event;
                    @pending_event = ();
                }

                @pending_event = ( $status_name );

                # Push channel if required
                if ( has_channel( $status ) ) {
                    my $channel = $status & 0x0f;
                    $channel++ unless $zero_index_channel;
                    push @pending_event, $channel + !$zero_index_channel;
                }

                next BYTE;
            } # end if status byte

            push @pending_event, shift @bytes;

            my $message_length = message_length( $pending_event[0] );
            my $remaining = $message_length - @pending_event;

            # A complete message denoted by length, not upcoming status bytes
            if ( $message_length && $remaining <= 0 ) {
                $self->_push_event;

                # Upcoming messages may include running status -
                # Status is not retransmitted if it's the same as prev. msg
                @pending_event = has_channel( status_byte( $pending_event[0] ) )
                    ? @pending_event[ 0, 1 ]
                    : $pending_event[ 0 ]
            }
        } # end while

        $events_queued;
    }

    method encode_events( @events ) {
        join '', map { $self->single_event( $_ ) } @events;
    }

    method throw( $e ) {
        $error_cb->( $e );
    }

    method continue { 'continue' }
    method stop { 'stop' }
}

1;
