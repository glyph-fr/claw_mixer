module ClawMixer
  class Clip < ClawMixer::Model
    attr_accessor :source, :name
    attr_writer :start_offset

    def start_offset
      @start_offset ||= 0
    end

    def length
      @length ||= source.info.length * source.info.samplerate
    end

    def end_offset
      @end_offset ||= start_offset + (length - 1)
    end

    def channels
      @channels ||= source.info.channels
    end

    def in?(first_sample, last_sample)
      (end_offset >= first_sample && last_sample >= start_offset)
    end

    def read_samples(start, length)
      source.seek(start)
      source.read(:float, length)
    rescue RubyAudio::Error => e
      puts "Called #read_samples on #{ name } with { start: #{ start }, length: #{ length } }, source infos : { length: #{ self.length }, end_offset: #{ end_offset} }"
      raise e
    end
  end
end
