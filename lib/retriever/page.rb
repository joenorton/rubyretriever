require 'eventmachine'
require 'em-synchrony'
require 'em-http-request'

module Retriever
  class Page
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
        errlog("Domain is not working. Try the non-WWW version.")
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
  end
end
