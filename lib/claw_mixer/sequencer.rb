module ClawMixer
  class Sequencer < ClawMixer::Model
    def tracks
      @tracks ||= []
    end

    def start
      0
    end

    def length
      tracks.map(&:length).max
    end

    def samplerate
      44100
    end
  end
end
