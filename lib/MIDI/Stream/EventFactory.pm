use v5.26;
use warnings;
use experimental qw/ signatures /;

package
    MIDI::Stream::EventFactory;

our $VERSION = 0.00;

require MIDI::Stream::Event::Note;
require MIDI::Stream::Event::PolyTouch;
require MIDI::Stream::Event::ControlChange;
require MIDI::Stream::Event::ProgramChange;
require MIDI::Stream::Event::AfterTouch;
require MIDI::Stream::Event::PitchBend;
require MIDI::Stream::Event::SysEx;
require MIDI::Stream::Event::TimeCode;
require MIDI::Stream::Event::SongPosition;
require MIDI::Stream::Event::SongSelect;

sub event( $class, $message ) {
    my $status = $message->[0];
    return if $status < 0x80;

    my sub instance( $name = undef ) {
        my $class = 'MIDI::Stream::Event' . ( $name ? "::$name" : '' );
        $class->new( message => $message );
    }

    # Single byte status
    return instance() if $status > 0xf3;

    # Channel events
    return instance( 'Note' )           if $status < 0xa0;
    return instance( 'PolyTouch' )      if $status < 0xb0;
    return instance( 'ControlChange' )  if $status < 0xc0;
    return instance( 'ProgramChange' )  if $status < 0xd0;
    return instance( 'AfterTouch' )     if $status < 0xe0;
    return instance( 'PitchBend' )      if $status < 0xf0;

    # System events
    return instance( 'SysEx' )        if $status == 0xf0;
    return instance( 'TimeCode' )     if $status == 0xf1;
    return instance( 'SongPosition' ) if $status == 0xf2;
    return instance( 'SongSelect' )   if $status == 0xf3;
}

;
