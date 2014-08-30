$:.push File.expand_path('../../lib', __FILE__)

require 'claw_mixer'

def file_path(name)
  File.expand_path("../#{ name }", __FILE__)
end

def open_sound(name)
  RubyAudio::Sound.open(file_path(name))
end
