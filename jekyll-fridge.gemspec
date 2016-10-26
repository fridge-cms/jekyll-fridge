lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jekyll-fridge/version'

Gem::Specification.new do |spec|
  spec.add_development_dependency 'bundler', '~> 1.0'
  spec.add_dependency 'jekyll', '>= 3.0'
  spec.add_dependency 'fridge_api', '~> 0.3'
  spec.authors = ["Mike Kruk"]
  spec.email = ['mike@ripeworks.com']
  spec.summary = %q{Jekyll plugin for building sites using Fridge content}
  spec.description = %q{Jekyll plugin for building sites using Fridge content}
  spec.files = %w(Rakefile LICENSE README.md jekyll-fridge.gemspec)
  spec.files += Dir.glob("lib/**/*.rb")
  spec.homepage = 'https://github.com/fridge-cms/jekyll-fridge'
  spec.licenses = ['MIT']
  spec.name = 'jekyll-fridge'
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 1.9.2'
  spec.required_rubygems_version = '>= 1.3.5'
  spec.version = Jekyll::Fridge::VERSION.dup
end
