require File.expand_path("../test_helper", __FILE__)

json = File.read(file_path('samples/project.json'))

parser = ClawMixer::Parser.new(json)
parser.local_sources = true
sequencer = parser.parse

if File.exist?(file_path('exports/project.wav'))
  File.unlink(file_path('exports/project.wav'))
end

exporter = ClawMixer::Exporter.new(sequencer)

progress_bar = ProgressBar.create(
  title: 'Exporting',
  total: exporter.buffers_count,
  length: 80,
  format: '%t: |%B| %P%% - %E'
)

exporter.run(file_path('exports/project.wav')) do |count|
  progress_bar.increment
end

puts "done !"

puts "Playing now ..."
`play #{ file_path('exports/project.wav') }`
