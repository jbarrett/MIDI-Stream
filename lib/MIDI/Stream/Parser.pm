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
    field $concat_multibyte    :param = 1;
    field $sysex_f0_terminates :param = 1;
    field $sysex_as_string     :param = 1;

    field $mode_14bit :param = 0;
    field $mode_rpn   :param = $mode_14bit;
    field $mode_nrpn  :param = $mode_14bit;

    field $error_cb :param = sub { croak @_; };
    field $event_cb :param = sub { @_ };
    field $filter_cb = {};

    field $name :param = 'midi_stream:' . gettimeofday;

    field @events;
    field @pending_event;


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
        @return_events;
    }

    # TODO: Lexical-scope-ise these when feature available

    method _push_event( $event = undef ) {
        state $t = [ gettimeofday ];
        $event //= \@pending_event;

        # note on with velocity 0 is note off
        $event->[0] = 'note_off'
            if ( $event->[0] eq 'note_on' && $event->[3] == 0 );

        if ( $event->[0] eq 'sysex' && $sysex_as_string ) {
            $event = [
                sysex =>
                join '',
                map { chr } @pending_event[ 1 .. $#pending_event ]
            ];
        }

        push @events, $event;
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
        my $ret = 0;

        BYTE:
        while ( @bytes ) {

            # Status byte - start/end of message
            if ( is_status_byte( $bytes[0] ) ) {
                my $status = shift @bytes;
                my $status_name = status_name( $status );

                $self->throw( sprintf( "Unsupported status type: 0x%x", $status ) )
                    unless $status_name;

                # Real-Time messages can appear inside other messages
                if ( is_realtime( $status_name ) ) {
                    $self->_push_event( [ $status_name ] );
                    next BYTE;
                }

                # Non Real-Time single byte statuses
                if ( message_length( $status ) == 1 ) {
                    $self->throw( "Non Real-Time message $status_name received while processing $pending_event[0]" )
                        if @pending_event;
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

                $self->throw( "Event $pending_event[0] was not complete before $status_name received" )
                    if @pending_event;

                @pending_event = ( $status_name );

                # Push channel if required
                if ( has_channel( $status ) ) {
                    my $channel = $status & 0x0f;
                    $channel++ unless $zero_index_channel;
                    push @pending_event, $channel + !$zero_index_channel;
                }

                next BYTE;
            } # end if status byte

            my $message_length = message_length( $pending_event[0] );
            my $remaining = $message_length - @pending_event;

            # A complete message denoted by length, not upcoming status bytes
            if ( $message_length && $remaining <= 0 ) {
                $self->_push_event;

                # Look ahead
                if ( is_status_byte( $bytes[0] ) ) {
                    @pending_event = ();
                }
                else {
                    # Probable running status - keep relevant pieces of pending event
                    @pending_event = has_channel( status_byte( $pending_event[0] ) )
                        ? @pending_event[ 0, 1 ]
                        : $pending_event[ 0 ]
                }
            }

            # Pull up-to the remaining number of bytes for the message,
            # if we know the length.
            # If we don't know the length, plop bytes onto the pending event
            # one-at-a-time ... which may be faster than any grepology
            # required for look ahead processing.
            push @pending_event, $message_length
                ? splice @bytes, 0, $remaining
                : shift @bytes;

        } # end while
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

