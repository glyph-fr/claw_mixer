require 'terminal-table'

module ClawMixer
  class Clip < ClawMixer::Model
    attr_accessor :id, :source, :name

    attr_writer :source_offset, :begin_offset, :end_offset,
                :duration

    # Offset between the first second of the source and the first second
    # of the clip
    #
    def begin_offset
      @begin_offset ||= 0
    end

    def begin_sample_offset
      @begin_sample_offset ||= (begin_offset * samplerate).round
    end

    # Offset between the first second of the song and the first second
    # of the source
    #
    # We must imagine that there is some invisible part of the source that
    # may begin before when the clip starts. This second offset is represented
    # by #begin_offset
    #
    def source_offset
      @source_offset ||= 0
    end

    def source_sample_offset
      @source_sample_offset ||= (source_offset * samplerate).round
    end

    # Offset between the first second of the song and the first second
    # of the clip
    #
    def start_offset
      @start_offset ||= begin_offset + source_offset
    end

    def start_sample_offset
      @start_sample_offset ||= (begin_sample_offset + source_sample_offset).round
    end

    # Offset between the first second of the song and the last second
    # of the clip
    #
    def end_offset
      @end_offset ||= start_offset + duration
    end

    def end_sample_offset
      @end_sample_offset ||= (start_sample_offset + length).round
    end

    def duration
      @duration ||= end_offset - begin_offset
    end

    def length
      @length ||= (duration * samplerate).round
    end

    def source_duration
      @source_duration ||= source.info.length
    end

    def source_length
      @source_length ||= (source_duration * samplerate).round
    end

    def source_window_start
      [source_length - begin_sample_offset, 0].max
    end

    def source_window_end
      [source_length - begin_sample_offset, length].min
    end

    def samplerate
      @samplerate ||= source.info.samplerate
    end

    def channels
      @channels ||= source.info.channels
    end

    def seek_source(position)
      source.seek(position + begin_sample_offset)
    end

    def in?(first_sample, last_sample)
      source_window_end >= first_sample && last_sample >= start_sample_offset
    end

    def read_samples(start, length)
      seek_source(start)
      source.read(:float, length)
    rescue StandardError, NoMemoryError => e
      infos = []

      infos << ['name', name]

      infos << ['Requested data']

      infos << ['Start', start]
      infos << ['Length', length]

      infos << ['Clip data']

      %w(offset sample_offset).each do |suffix|
        %w(begin source start end).each do |key|
          method = [key, suffix].join('_')
          infos << [method, send(method)]
        end
      end

      infos << ['duration', duration]
      infos << ['length', self.length]
      infos << ['source_duration', source_duration]
      infos << ['source_length', source_length]

      # Empty lines to let the progress bar appear as it was before the error
      puts "\n\n"

      puts "----------------------------"
      puts "Error when calling #read_samples"
      puts Terminal::Table.new(rows: infos)
      puts "----------------------------"

      raise e
    end
  end
end
