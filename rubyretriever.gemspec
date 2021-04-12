# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'retriever/version'

Gem::Specification.new do |s|
  s.required_ruby_version = ['>= 2.0', '<= 2.8']
  s.platform    = Gem::Platform::RUBY
  s.version     = Retriever::VERSION
  s.name        = 'rubyretriever'
  s.date        = '2016-04-11'
  s.summary     = 'Ruby Web Crawler & File Harvester'
  s.description = 'Asynchronous web crawler, scraper and file harvester'
  s.authors     = ['Joe Norton']
  s.email       = ['joe@norton.io']
  s.homepage    = 'http://norton.io/rubyretriever/'
  s.license     = 'MIT'
  # If you need to check in files that aren't .rb files, add them here
  s.files        = Dir['{lib}/**/*.rb', 'bin/*', 'LICENSE', '*.md',
                       '{spec}/*.rb']
  s.require_path = 'lib'
  s.rubyforge_project         = 'rubyretriever'

  # If you need an executable, add it here
  s.executables = ['rr']
  s.required_rubygems_version = '>= 1.3.6'

  # If you have other dependencies, add them here
  s.add_runtime_dependency 'em-synchrony'
  s.add_runtime_dependency 'em-http-request'
  s.add_runtime_dependency 'ruby-progressbar'
  s.add_runtime_dependency 'bloomfilter-rb'
  s.add_runtime_dependency 'addressable'
  s.add_runtime_dependency 'htmlentities'
  s.add_runtime_dependency 'nokogiri'

  s.add_development_dependency 'bundler', '~> 1.6'
  s.add_development_dependency 'rake', '~> 10.3'
  s.add_development_dependency 'rspec', '~> 2.14'
  s.add_development_dependency 'pry'
end
