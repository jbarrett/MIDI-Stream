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
    use MIDI::Stream::Event;
    use Syntax::Operator::Equ;
    use namespace::autoclean;

    field $zero_index_channel  :param = 1;
    field $detect_note_off     :param = 1;
    field $retain_events       :param = 1;

    field $mode_14bit :param = 0;
    field $mode_rpn   :param = $mode_14bit;
    field $mode_nrpn  :param = $mode_14bit;

    field $warn_cb :param = sub { carp( @_ ); };
    field $event_cb :param = sub { @_ };
    field $filter_cb = {};

    field $name :reader :param = 'midi_stream:' . gettimeofday;

    field @events;
    field @pending_event;
    field $events_queued = 0;
    field $message_length;

    method attach_callback( $event, $callback ) {
        if ( reftype $event equ 'ARRAY' ) {
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
        my $stream_event = MIDI::Stream::Event->event( $event );

        if ( !$stream_event ) {
            $self->_w( "Ignoring unknown status $event->[0]" );
            return;
        }

        $events_queued = 1;

        push @events, $stream_event if $retain_events;

        my $dt = tv_interval( $t );
        $t = [ gettimeofday ];

        my @callbacks = ( $filter_cb->{ all } // [] )->@*;
        push @callbacks, ( $filter_cb->{ $stream_event->name } // [] )->@*;

        for my $cb ( @callbacks ) {
            last unless $cb->( $dt, $stream_event ) equ $self->continue;
        }

        $event_cb->( $stream_event );
    }

    method _reset_pending_event( $status = undef ) {
        @pending_event = ();
        push @pending_event, $status if defined $status;
        $message_length = message_length( $status );
    }

    method parse( $bytestring ) {
        my @bytes = unpack 'C*', $bytestring;
        my $status;

        BYTE:
        while ( @bytes ) {

            # Status byte - start/end of message
            if ( $bytes[0] & 0x80 ) {
                my $status = shift @bytes;

                # End-of-Xclusive
                if ( $status == 0xf7 ) {
                    $self->_w( "EOX received for non-SysEx message - ignoring!") && next BYTE
                        unless $pending_event[0] == 0xf0;
                    $self->_push_event;
                    $self->_reset_pending_event;
                    next BYTE;
                }

                # Real-Time messages can appear within other messages.
                if ( is_realtime( $status ) ) {
                    $self->_push_event( [ $status ] );
                    next BYTE;
                }

                # Any non-Real-Time status byte ends a SysEx
                # Push the sysex and proceed ...
                if ( @pending_event && $pending_event[0] == 0xf0 ) {
                    $self->_push_event;
                }

                # Should now be able to push any single-byte statuses,
                # e.g. Tune request
                if ( message_length( $status ) == 1 ) {
                    $self->_push_event( [ $status ] );
                    next BYTE;
                }

                $self->_reset_pending_event( $status );
                next BYTE;
            } # end if status byte
            next BYTE unless @pending_event;

            push @pending_event, shift @bytes;
            my $remaining = $message_length - @pending_event;

            # A complete message denoted by length, not upcoming status bytes
            if ( $message_length && $remaining <= 0 ) {
                $self->_push_event;
                $self->_reset_pending_event( $pending_event[0] );
            }
        } # end while

        $events_queued;
    }

    method encode_events( @events ) {
        join '', map { $self->single_event( $_ ) } @events;
    }

    method _w( $msg ) {
        $warn_cb->( $msg );
    }

    method continue { 'continue' }
    method stop { 'stop' }
}

1;
