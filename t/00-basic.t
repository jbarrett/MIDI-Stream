use Test2::V0;
use Test::Lib;
use MIDI::Stream::Test 'run_file';

run_file({
   midi_version => 1,
   test_type => 'decoding',
   file_spec => '000_example.json'
});

ok(1);

done_testing;
