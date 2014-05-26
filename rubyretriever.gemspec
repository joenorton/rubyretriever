# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'retriever/version'

Gem::Specification.new do |s|
  s.required_ruby_version = '>= 1.8.6'
  s.platform    = Gem::Platform::RUBY
  s.version     = Retriever::VERSION
  s.name        = 'rubyretriever'
  s.date        = '2014-05-25'
  s.summary     = "Ruby Web Crawler & File Harvester"
  s.description = "General purpose web crawler, site mapper, and file harvester"
  s.authors     = ["Joe Norton"]
  s.email       = ["joe@softwarebyjoe.com"]
  s.homepage    =
    'http://github.com/joenorton/rubyretriever'
  s.license       = 'MIT'
   # If you need to check in files that aren't .rb files, add them here
  s.files        = Dir["{lib}/**/*.rb", "bin/*", "LICENSE", "*.md","{spec}/*.rb"]
  s.require_path = 'lib'
    # lol - required for validation
  s.rubyforge_project         = 'rubyretriever'

  # If you need an executable, add it here
  s.executables = ["rr"]
  s.required_rubygems_version = ">= 1.3.6"

    # If you have other dependencies, add them here
  s.add_runtime_dependency 'em-synchrony'
  s.add_runtime_dependency 'em-http-request'
  s.add_runtime_dependency 'ruby-progressbar'
  s.add_runtime_dependency 'bloomfilter-rb'

  s.add_development_dependency 'bundler', '~> 1.6'
  s.add_development_dependency 'rake', '~> 10.3'
  s.add_development_dependency 'rspec', '~> 2.14'
end