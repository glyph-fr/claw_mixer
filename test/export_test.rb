require File.expand_path("../test_helper", __FILE__)

sequencer = ClawMixer::Sequencer.new

kick_track = ClawMixer::Track.new
clap_track = ClawMixer::Track.new

8.times do |index|
  kick_clip = ClawMixer::Clip.new(source: open_sound('samples/kick.wav'), name: 'kick')
  kick_clip.start_offset = 44_100 * index

  clap_clip = ClawMixer::Clip.new(source: open_sound('samples/clap.wav'), name: 'clap')
  clap_clip.start_offset = (44_100 * index) + 22_100

  kick_track.clips << kick_clip
  clap_track.clips << clap_clip
end

sequencer.tracks << kick_track
sequencer.tracks << clap_track

if File.exist?(file_path('exports/sequence.wav'))
  File.unlink(file_path('exports/sequence.wav'))
end

print "Exporting ... "
ClawMixer::Exporter.new(sequencer).run(file_path('exports/sequence.wav'))
puts "done !"

puts "Playing now ..."
`play #{ file_path('exports/sequence.wav') }`
