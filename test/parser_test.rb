require File.expand_path("../test_helper", __FILE__)

json = File.read(file_path('samples/project.json'))
parser = ClawMixer::Parser.new(json)
sequencer = parser.parse

if File.exist?(file_path('exports/project.wav'))
  File.unlink(file_path('exports/project.wav'))
end

print "Exporting ... "
ClawMixer::Exporter.new(sequencer).run(file_path('exports/project.wav'))
puts "done !"

puts "Playing now ..."
`play #{ file_path('exports/project.wav') }`
