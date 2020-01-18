# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tempo/version'

Gem::Specification.new do |spec|
  spec.name          = 'tempo'
  spec.version       = Tempo::VERSION
  spec.authors       = ['Benedikt Deicke']
  spec.email         = ['benedikt@benediktdeicke.com']
  spec.description   = %q{Tempo is a simple templating system based on the Handlebars syntax.}
  spec.summary       = %q{Tempo is a simple templating system based on the Handlebars syntax. It provides a safe framework to render user provided templates without affecting the security of the server they are rendered on. It is designed to be easily extendable, without relying on global state.}
  spec.homepage      = 'https://github.com/benedikt/tempo'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake', '~> 10.1'
  spec.add_development_dependency 'rspec', '~> 3.0'

  spec.add_dependency 'rltk', '~> 2.2'
end
