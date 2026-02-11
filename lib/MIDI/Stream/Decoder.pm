use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: MIDI bytestream decoder

package MIDI::Stream::Decoder;
class MIDI::Stream::Decoder :isa( MIDI::Stream );

our $VERSION = 0.00;

use Scalar::Util qw/ reftype /;
use Time::HiRes qw/ gettimeofday tv_interval /;
use Carp qw/ carp croak /;
use MIDI::Stream::Tables qw/ is_cc is_realtime message_length combine_bytes /;
use MIDI::Stream::FIFO;
use MIDI::Stream::EventFactory;
use namespace::autoclean;

field $retain_events :param = 1;

field $enable_14bit_cc :param = 0;
field @cc;

field $event_cb :param = sub { @_ };
field $filter_cb = {};

field $clock_ppqn :param = 24;
field $clock_samples :param = 24;
field $clock_fifo = MIDI::Stream::FIFO->new( length => $clock_samples );
field $round_tempo :param = 0;

field @events;
field @pending_event;
field $message_length;

method attach_callback( $event, $callback ) {
    if ( reftype $event eq 'ARRAY' ) {
        $self->attach_callback( $_, $callback ) for $event->@*;
        return;
    }
    push $filter_cb->{ $event }->@*, $callback;
}

method cancel_callbacks( $event ) {
    delete $filter_cb->{ $event };
}

method events {
    splice @events;
}

method fetch_one_event {
    pop @events;
}

my $_expand_cc = method( $event ) {
    return $event unless is_cc( $event->[ 0 ] );
    return $event unless $enable_14bit_cc;
    return $event if $event->[ 1 ] > 0x3f;
    return $event if $event->[ 2 ] > 0x7f;

    if ( $event->[ 1 ] & 0x20 ) {
        my $msb = $cc[ $event->[ 1 ] & ~0x20 ];
        return unless defined $msb;
        $event->[ 2 ] = combine_bytes( $event->[ 2 ], $msb );
        $event->[ 1 ] &= ~0x20;
        return $event;
    }

     $cc[ $event->[ 1 ] ] = $event->[ 2 ];
     return;
};

my $_sample_clock = method() {
    state $t = [ gettimeofday ];
    $clock_fifo->add( tv_interval( $t ) );
    $t = [ gettimeofday ];
};

my $_push_event = method( $event = undef ) {
    state $t = [ gettimeofday ];
    # Do not use a reference to @pending_event!
    # Contents will have changed by the time you get round to using it.
    $event //= [ @pending_event ];
    $event = $self->$_expand_cc( $event );
    return unless $event;
    my $dt = tv_interval( $t );
    $t = [ gettimeofday ];

    my $stream_event = MIDI::Stream::EventFactory->event( $event );

    if ( !$stream_event ) {
        carp( "Ignoring unknown status $event->[0]" );
        return;
    }

    push @events, $stream_event if $retain_events;

    my @callbacks = ( $filter_cb->{ all } // [] )->@*;
    push @callbacks, ( $filter_cb->{ $stream_event->name } // [] )->@*;

    for my $cb ( @callbacks ) {
        no warnings 'uninitialized';
        last unless $cb->( $dt, $stream_event ) eq $self->continue;
    }

    $event_cb->( $stream_event );
};

my $_reset_pending_event = method( $status = undef ) {
    @pending_event = ();
    push @pending_event, $status if defined $status;
    $message_length = message_length( $status );
};

method decode( $bytestring ) {
    my @bytes = unpack 'C*', $bytestring;
    my $status;

    BYTE:
    while ( @bytes ) {

        # Status byte - start/end of message
        if ( $bytes[0] & 0x80 ) {
            my $status = shift @bytes;

            # Sample the clock to determine tempo ASAP
            $status == 0xf8 && $self->$_sample_clock();

            # End-of-Xclusive
            if ( $status == 0xf7 ) {
                carp( "EOX received for non-SysEx message - ignoring!") && next BYTE
                    unless $pending_event[0] == 0xf0;
                $self->$_push_event();
                $self->$_reset_pending_event();
                next BYTE;
            }

            # Real-Time messages can appear within other messages.
            if ( is_realtime( $status ) ) {
                # Push unless we have an undefined realtime status
                $self->$_push_event( [ $status ] ) unless $status == 0xf9 || $status == 0xfd;
                next BYTE;
            }

            # Any non-Real-Time status byte ends a SysEx
            # Push the pending sysex and proceed ...
            if ( @pending_event && $pending_event[0] == 0xf0 ) {
                $self->$_push_event();
            }

            # Undefined system statuses which should reset running status -
            # a full message needs to be received after this
            if ( $status == 0xf4 || $status == 0xf5 ) {
                @pending_event = ();
                next BYTE;
            }

            # Should now be able to push any single-byte statuses,
            # e.g. Tune request
            if ( message_length( $status ) == 1 ) {
                $self->$_push_event( [ $status ] );
                next BYTE;
            }

            $self->$_reset_pending_event( $status );
            next BYTE;
        } # end if status byte

        my $byte = shift @bytes;
        next BYTE unless @pending_event;

        push @pending_event, $byte;
        my $remaining = $message_length - @pending_event;

        # A complete message denoted by length, not upcoming status bytes
        if ( $message_length && $remaining <= 0 ) {
            $self->$_push_event();
            $self->$_reset_pending_event( $pending_event[0] );
        }
    } # end while

    scalar @events;
}

method tempo {
    my $tempo = 60 / ( $clock_fifo->average * $clock_ppqn );
    $round_tempo ? sprintf( '%.0f', $tempo ) : $tempo;
}

method encode_events( @events ) {
    join '', map { $self->single_event( $_ ) } @events;
}

1;
