require 'uri'
require 'net/http'
require 'tempfile'

module ClawMixer
  class Parser
    attr_writer :local_sources
    attr_reader :sequencer, :data

    def initialize(json)
      @data = JSON.parse(json)
    end

    def local_sources
      @local_sources ||= false
    end

    def downloaded_files
      @downloaded_files ||= {}
    end

    def parse
      @sequencer = Sequencer.new
      @data['tracks'].each(&method(:add_track_from))
      @sequencer
    end

    private

    def add_track_from(track_data)
      track = Track.new(name: track_data['name'], gain: track_data['volume'])
      track_data['clips'].each do |clip_data|
        add_clip_to_track_from(clip_data, track)
      end
      sequencer.tracks << track
    end

    def add_clip_to_track_from(clip_data, track)
      audio_source = audio_sources[clip_data['audio_source_id']]
      audio_file = load_source(audio_source)

      clip = Clip.new(
        id: clip_data['id'],
        name: audio_source['name'],
        source: audio_file,
        source_offset: clip_data['source_offset'],
        begin_offset: clip_data['begin_offset'],
        duration: clip_data['duration']
      )
      track.clips << clip
    end

    def audio_sources
      @audio_sources ||= data['audio_sources'].each_with_object({}) do |source, hash|
        hash[source['id']] = source
      end
    end

    def load_source(audio_source)
      if downloaded_files[audio_source['url']]
        local_path = downloaded_files[audio_source['url']]
      else
        local_path = if local_sources
          File.expand_path(
            "../../../test/samples/#{ audio_source['url'] }",
            __FILE__
          ).to_s
        else
          download_file(audio_source['url'])
        end

        if audio_source['type'].match(/mp3/)
          local_path = convert_to_wav(local_path)
        end

        downloaded_files[audio_source['url']] = local_path
      end

      RubyAudio::Sound.new(local_path)
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

      puts "OK"

      destination.path
    end

    def convert_to_wav(path)
      wav_path = "#{ path.gsub(/\.mp3/, '') }.wav"

      # If already converted, return wav path directly
      # Used for local_sources options
      return wav_path if File.exist?(wav_path)

      print "Decoding ... "
      `lame -b 44.1 --decode "#{ path }" "#{ wav_path }" > /dev/null 2>&1`
      puts "OK"
      wav_path
    end

    def tempfile_name_from(url)
      filename = File.basename(url).split('?').shift
      [filename, File.extname(filename)]
    end
  end
end
