# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bottler/version'

Gem::Specification.new do |spec|
  spec.name          = 'bottler'
  spec.version       = Bottler::VERSION
  spec.authors       = ['Andrew Kuklewicz']
  spec.email         = ['andrew@prx.org']

  spec.summary       = %q{Bottler likes to puts messages in bottles.}
  spec.description   = %q{Bottler is a gem to support using pub sub messages for events, built on top of shoryuken.}
  spec.homepage      = 'https://github.com/PRX/bottler'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'shoryuken', '~> 1.0'

  spec.add_development_dependency 'bundler', '~> 1.8'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest'
end
