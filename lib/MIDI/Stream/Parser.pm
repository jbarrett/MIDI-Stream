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
    use MIDI::Stream::Tables qw/ is_cc is_realtime message_length /;
    use MIDI::Stream::FIFO;
    use MIDI::Stream::Event;
    use Syntax::Operator::Equ;
    use namespace::autoclean;

    field $zero_index_channel  :param = 1;
    field $detect_note_off     :param = 1;
    field $retain_events       :param = 1;

    field $enable_14bit :param = 0;
    field $enable_rpn   :param = 0;
    field $enable_nrpn  :param = 0;
    field $last_msb     = [];
    field $active_rpn;
    field $active_nrpn;

    field $warn_cb :param = sub { carp( @_ ); };
    field $event_cb :param = sub { @_ };
    field $filter_cb = {};

    field $name :reader :param = 'midi_stream:' . gettimeofday;

    field $clock_samples :param = 24;
    field $clock_fifo = MIDI::Stream::FIFO->new( length => $clock_samples );
    field $round_tempo :param = 0;

    field @events;
    field @pending_event;
    field $events_queued = 0;
    field $message_length;

    field @cc;

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

    my method _expand_cc( $event ) {
        return $event unless is_cc( $event->[ 0 ] );
        return $event unless $enable_14bit;
        return $event if $event->[ 1 ] > 0x40;
        return $event if $event->[ 2 ] > 0x7f;

        if ( $event->[ 1 ] & 0x20 ) {
            my $msb = $cc[ $event->[ 1 ] & ~0x20 ];
            return unless defined $msb;
            $event->[ 2 ] = combine_bytes( $msb, $event->[ 2 ] );
            return $event;
        }

         $cc[ $event->[ 1 ] ] = $event->[ 2 ];
         return;
    }

    my method _sample_clock() {
        state $t = [ gettimeofday ];
        $clock_fifo->add( tv_interval( $t ) );
        $t = [ gettimeofday ];
    }

    my method _push_event( $event = undef ) {
        state $t = [ gettimeofday ];
        $event //= [ @pending_event ]; # Do not use a reference to @pending_event, contents may change
        $event = $self->&_expand_cc( $event );
        return unless $event;
        my $dt = tv_interval( $t );
        $t = [ gettimeofday ];

        my $stream_event = MIDI::Stream::Event->event( $event );

        if ( !$stream_event ) {
            $self->&_warn( "Ignoring unknown status $event->[0]" );
            return;
        }

        $events_queued++;

        push @events, $stream_event if $retain_events;

        my @callbacks = ( $filter_cb->{ all } // [] )->@*;
        push @callbacks, ( $filter_cb->{ $stream_event->name } // [] )->@*;

        for my $cb ( @callbacks ) {
            last unless $cb->( $dt, $stream_event ) equ $self->continue;
        }

        $event_cb->( $stream_event );
    }

    my method _reset_pending_event( $status = undef ) {
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

                # Sample the clock to determine tempo ASAP
                $status == 0xf8 && $self->&_sample_clock;

                # End-of-Xclusive
                if ( $status == 0xf7 ) {
                    $self->&_warn( "EOX received for non-SysEx message - ignoring!") && next BYTE
                        unless $pending_event[0] == 0xf0;
                    $self->&_push_event;
                    $self->&_reset_pending_event;
                    next BYTE;
                }

                # Real-Time messages can appear within other messages.
                if ( is_realtime( $status ) ) {
                    $self->&_push_event( [ $status ] );
                    next BYTE;
                }

                # Any non-Real-Time status byte ends a SysEx
                # Push the sysex and proceed ...
                if ( @pending_event && $pending_event[0] == 0xf0 ) {
                    $self->&_push_event;
                }

                # Should now be able to push any single-byte statuses,
                # e.g. Tune request
                if ( message_length( $status ) == 1 ) {
                    $self->&_push_event( [ $status ] );
                    next BYTE;
                }

                $self->&_reset_pending_event( $status );
                next BYTE;
            } # end if status byte

            my $byte = shift @bytes;
            next BYTE unless @pending_event;

            push @pending_event, $byte;
            my $remaining = $message_length - @pending_event;

            # A complete message denoted by length, not upcoming status bytes
            if ( $message_length && $remaining <= 0 ) {
                $self->&_push_event;
                $self->&_reset_pending_event( $pending_event[0] );
            }
        } # end while

        $events_queued;
    }

    method tempo {
        my $tempo = 60 / ( $clock_fifo->average * 24 );
        $round_tempo ? sprintf( '%.0f', $tempo ) : $tempo;
    }

    method encode_events( @events ) {
        join '', map { $self->single_event( $_ ) } @events;
    }

    my method _warn( $msg ) {
        $warn_cb->( $msg );
    }

    method continue { MIDI::Stream::Tables::continue() }
    method stop { MIDI::Stream::Tables::stop() }
}

1;
