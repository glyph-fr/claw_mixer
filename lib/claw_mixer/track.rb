module ClawMixer
  class Track < ClawMixer::Model
    attr_writer :volume

    def volume
      @volume ||= 0
    end

    def clips
      @clips ||= []
    end

    def length
      clips.reduce(0) do |max, clip|
        [max, clip.start_offset + clip.length].max
      end
    end

    def samples_between(first_sample, last_sample)
      clips.each do |clip|
        if clip.in?(first_sample, last_sample)
          return samples_for_clip(clip, first_sample, last_sample)
        end
      end

      # If no clip matched the desired range, return a buffer full of zeros
      Array.new(((last_sample - first_sample) + 1), [0.0, 0.0])
    end

    def samples_for_clip(clip, first_sample, last_sample)
      offset = first_sample - clip.start_offset
      start = [offset, 0].max

      length = (last_sample - first_sample) + (offset < 0 ? offset : 0)

      samples = clip.read_samples(start, length)

      fill_buffer(samples, 0..(-offset - 1), clip.channels) if offset < 0

      samples
    end

    def fill_buffer(original_buffer, range, channels, value = 0.0)
      buffer_size = original_buffer.real_size + range.size
      buffer = RubyAudio::Buffer.float(buffer_size, channels)

      range.each do |index|
        buffer[index] = if channels == 1
          value
        else
          channels.times.map { value }
        end
      end

      start_index = buffer.real_size

      original_buffer.each_with_index do |sample, index|
        buffer[index + start_index] = sample
      end

      buffer
    end
  end
end