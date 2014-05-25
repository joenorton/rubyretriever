Gem::Specification.new do |s|
  s.required_ruby_version = '>= 1.8.6'
  s.platform    = Gem::Platform::RUBY
  s.version     = '0.0.2'
  s.name        = 'RubyRetriever'
  s.date        = '2014-05-25'
  s.summary     = "Ruby Web Crawler & File Harvester"
  s.description = "Creates sitemaps, or scoure entire sites for a certain filetype."
  s.authors     = ["Joe Norton"]
  s.email       = ["joe@softwarebyjoe.com"]
  s.homepage    =
    'http://github.com/joenorton/rubyretriever'
  s.license       = 'GPLv3'
   # If you need to check in files that aren't .rb files, add them here
  s.files        = Dir["{lib}/**/*.rb", "bin/*", "LICENSE", "*.md","{spec}/*.rb"]
  s.require_path = 'lib'
    # lol - required for validation
  s.rubyforge_project         = "RubyRetriever"  

  # If you need an executable, add it here
  s.executables = ["rr"]
  s.required_rubygems_version = ">= 1.3.6"

    # If you have other dependencies, add them here
    gem "em-synchrony"
    gem "ruby-progressbar"
end