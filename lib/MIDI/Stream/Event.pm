use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: MIDI event base class

use experimental qw/ signatures /;

class MIDI::Stream::Event {
    use Carp qw/ croak /;
    use MIDI::Stream::Tables qw/ status_name keys_for /;
    use Module::Load;
    use namespace::autoclean;

    field $name :reader;
    field $message :reader :param;
    field $bytes;
    field $status :reader;

    method bytes {
        $bytes //= join '', map { chr } $message->@*;
    }

    sub event( $class, $message ) {
        my $status = $message->[0];
        return if $status < 0x80;

        my sub instance( $name ) {
            my $class = __PACKAGE__ . ( $name ? "::$name" : '' );
            load $class;
            $class->new( message => $message );
        }

        # Single byte status
        return instance() if $status > 0xf7;

        # Channel events
        return instance( 'Note' )           if $status < 0xa0;
        return instance( 'PolyTouch' )      if $status < 0xb0;
        return instance( 'ControlChange' )  if $status < 0xc0;
        return instance( 'ProgramChange' )  if $status < 0xd0;
        return instance( 'AfterTouch' )     if $status < 0xe0;
        return instance( 'PitchBend' )      if $status < 0xf0;
    }

    method as_hashref {
        +{
            map { $_ => $self->$_ }
                ( 'name', keys_for( $self->name )->@* )
        };
    }

    method TO_JSON { $self->as_hashref };

    method as_arrayref {
        [
            $self->name =>
            map { $self->$_ } keys_for( $self->name )->@*
        ]
    }

    ADJUST {
        $name = status_name( $message->[0] ) // 'unknown';
        $status = $message->[0];
        # note on with velocity 0 is note off
        $name = 'note_off' if $status < 0xa0 && !$message->[2];
    }
}

1;
