# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'announce/version'

Gem::Specification.new do |spec|
  spec.name          = 'announce'
  spec.version       = Announce::VERSION
  spec.authors       = ['Andrew Kuklewicz']
  spec.email         = ['andrew@prx.org']

  spec.summary       = %q{Announce is for pubsub of messages}
  spec.description   = %q{Announce is for pubsub of messages for events, built on other gems like shoryuken.}
  spec.homepage      = 'https://github.com/PRX/announce'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'shoryuken', '~> 1.0'
  spec.add_development_dependency 'bundler', '~> 1.8'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'growl'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-minitest'
  spec.add_development_dependency 'dotenv'
end
