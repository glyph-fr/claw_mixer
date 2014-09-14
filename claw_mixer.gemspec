$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'claw_mixer/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'claw_mixer'
  s.version     = ClawMixer::VERSION
  s.authors     = ['Valentin Ballestrino']
  s.email       = ['vala@glyph.fr']
  s.homepage    = 'http://www.claw-studio.com'
  s.summary     = 'Claw project mixer and exporter'
  s.description = 'Claw project mixer and exporter'

  s.files = Dir['{app,config,db,lib}/**/*'] + ['README.md']

  s.add_dependency 'ruby-audio'
  s.add_dependency 'ruby-progressbar'
end
