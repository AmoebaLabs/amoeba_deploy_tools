# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'amoeba_deploy_tools/version'

Gem::Specification.new do |s|
  s.name          = 'amoeba-deploy-tools'
  s.version       = AmoebaDeployTools::VERSION
  s.authors       = ['Daniel Jabbour', 'Hike Danakian']
  s.email         = 'sayhi@amoe.ba'
  s.summary       = 'Easy Chef Solo / Knife operation with Amoeba Deploy Tools.'
  s.description   = 'Easy Chef Solo / Knife operation with Amoeba Deploy Tools.'
  s.homepage      = 'https://github.com/AmoebaConsulting/amoeba-deploy-tools'
  s.license       = 'MIT'

  s.files         = %w(
    lib/amoeba_deploy_tools.rb
    bin/amoeba
  )
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']

  s.add_development_dependency 'bundler', '~> 1.3'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~> 2.14.1'
  s.add_development_dependency 'pry', '~> 0.9.12.4'

  s.add_dependency 'hashie',  '~> 2.0.5'
  s.add_dependency 'thor',    '~> 0.18.1'
  s.add_dependency 'cocaine', '~> 0.5.3'
end
