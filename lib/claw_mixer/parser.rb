require 'uri'
require 'net/http'
require 'tempfile'

module ClawMixer
  class Parser
    attr_reader :sequencer, :data

    def initialize(json)
      @data = JSON.parse(json)
    end

    def parse
      @sequencer = Sequencer.new
      @data['tracks'].each(&method(:add_track_from))
      @sequencer
    end

    private

    def add_track_from(track_data)
      track = Track.new(volume: track_data['volume'])
      track_data['clips'].each do |clip_data|
        add_clip_to_track_from(clip_data, track)
      end
      sequencer.tracks << track
    end

    def add_clip_to_track_from(clip_data, track)
      audio_source = audio_sources[clip_data['audio_source_id']]
      audio_file = load_source(audio_source)
      clip = Clip.new(source: audio_file, name: audio_source['name'])
      track.clips << clip
    end

    def audio_sources
      @audio_sources ||= data['audio_sources'].each_with_object({}) do |source, hash|
        hash[source['id']] = source
      end
    end

    def load_source(audio_source)
      local_path = download_file(audio_source['url'])

      if audio_source['type'].match(/mp3/)
        local_path = convert_to_wav(local_path)
      end

      RubyAudio::Sound.open(local_path)
    end

    def download_file(url)
      destination = Tempfile.new(tempfile_name_from(url))
      uri = URI.parse(url)

      print "Downloading #{ url } ..."
      Net::HTTP.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Get.new(uri)

        http.request(request) do |response|
          response.read_body do |chunk|
            destination.write(chunk)
          end
        end
      end

      puts "Done."
      destination.path
    end

    def convert_to_wav(path)
      wav_path = "#{ path.gsub(/\.mp3/, '') }.wav"
      print "Decoding #{ path } ... "
      `lame --decode #{ path } #{ wav_path }`
      puts "Done ! => #{ wav_path }"
      wav_path
    end

    def tempfile_name_from(url)
      filename = File.basename(url).split('?').shift
      [filename, File.extname(filename)]
    end
  end
end
