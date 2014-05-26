require 'eventmachine'
require 'em-synchrony'
require 'em-http-request'
require 'uri'
require 'retriever/link'

module Retriever
  class Page
    HREF_CONTENTS_RE = Regexp.new(/\shref=['|"]([^\s][a-z0-9\.\/\:\-\%\+\?\!\=\&\,\:\;\~\_]+)['|"][\s|\W]/ix).freeze

    def initialize(url, verbose)
      @url = url
      @v = verbose
    end

    def log(msg)
      puts "### #{msg}" if @v
    end

    def errlog(msg)
      raise "ERROR: #{msg}"
    end

    def call
      source
    end

    def links
      hrefs.map do |match|  #filter some malformed URLS that come in, this is meant to be a loose filter to catch all reasonable HREF attributes.
        link = match[0]

        Link.new(host, link).path
      end.uniq
    end

    def hrefs
      return [] unless source

      source.scan(HREF_CONTENTS_RE)
    end

    def source
      EM.synchrony do
        _source

        log "URL Crawled: #{url}"
        EventMachine.stop
      end

      _source.encode('UTF-8', :invalid => :replace, :undef => :replace) #.force_encoding('UTF-8') #ran into issues
    end

    def _source
      @source ||= EventMachine::HttpRequest.new(url).get.response

      if @source == ""
        log("Domain is not working. Try the non-WWW version.")
      end

      return @source
    rescue StandardError => e

      # the trap abrt is nescessary to handle the SSL error
      # for some ungodly reason it's the only way I found to handle it
      trap("ABRT"){
        puts "#{url} failed SSL Certification Verification"
      }
      raise e
    end

    private
    attr_reader :url

    def host
      URI(url).host
    end
  end
end
