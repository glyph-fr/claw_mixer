module ClawMixer
  class Exporter < ClawMixer::Model
    attr_reader :sequencer

    BUFFER_SIZE = 1024

    def initialize(sequencer)
      @sequencer = sequencer
    end

    def run(file_name, &callback)
      RubyAudio::Sound.open(file_name, 'w', out_info) do |out_file|
        (0..buffers_count).each do |buffer_index|
          buffer = frame_buffer(buffer_index)
          out_file.write(buffer)
          callback.call(buffer_index) if callback
        end
      end
    end

    def buffers_count
      (sequencer.length / BUFFER_SIZE).ceil
    end

    def frame_buffer(buffer_index)
      first_sample = buffer_index * BUFFER_SIZE
      last_sample = first_sample + BUFFER_SIZE - 1

      track_samples = sequencer.tracks.map do |track|
        track.samples_between(first_sample, last_sample)
      end

      mix_buffers(track_samples)
    end

    def mix_buffers(buffers)
      buffer = RubyAudio::Buffer.float(BUFFER_SIZE, 2)
      buffers_count = buffers.length

      BUFFER_SIZE.times.each do |index|
        mix = buffers.reduce([0, 0]) do |total, samples|
          total.each_with_index do |channel_total, channel_index|
            channel = samples[index]

            track_channel_sample = if channel.is_a?(Array)
              channel[channel_index]
            else
              channel || 0
            end

            total[channel_index] = channel_total + track_channel_sample
          end

          total
        end

        buffer[index] = mix.map do |sample|
          compressor.compress(sample, buffers_count)
        end
      end

      buffer
    end

    def compressor
      @compressor ||= LogDynRangeCompressor.new
    end

    def out_info
      @out_info ||= RubyAudio::SoundInfo.new(
        format: (RubyAudio::FORMAT_WAV | RubyAudio::FORMAT_PCM_16),
        channels: 2,
        samplerate: sequencer.samplerate
      )
    end
  end
end
