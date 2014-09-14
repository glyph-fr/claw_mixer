module ClawMixer
  class Clip < ClawMixer::Model
    attr_accessor :source, :name, :source_offset, :begin_offset, :end_offset,
                  :duration

    def begin_offset
      @begin_offset ||= 0
    end

    def source_offset
      @source_offset ||= 0
    end

    def duration
      @duration ||= source.info.length
    end

    def start_offset
      @start_offset ||= begin_offset * samplerate
    end

    def samplerate
      @samplerate ||= source.info.samplerate
    end

    def length
      @length ||= duration * samplerate
    end

    def end_offset
      @end_offset ||= start_offset + (length - 1)
    end

    def channels
      @channels ||= source.info.channels
    end

    def source_sample_offset
      @source_sample_offset ||= (source_offset * samplerate)
    end

    def seek_source(position)
      source.seek(position + (source_sample_offset))
    end

    def in?(first_sample, last_sample)
      (end_offset >= first_sample && last_sample >= begin_offset)
    end

    def read_samples(start, length)
      seek_source(start)
      source.read(:float, length)
    rescue RubyAudio::Error => e
      puts "Error when calling #read_samples on #{ name } with " \
           "{ start: #{ start }, length: #{ length } }, source infos : " \
           "{ length: #{ self.length }, end_offset: #{ end_offset } }"

      raise e
    end
  end
end
