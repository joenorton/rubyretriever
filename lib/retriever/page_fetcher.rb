module Retriever
  class PageFetcher
    def initialize(url)
      @url = url
    end

    def lg(msg)
      puts "### #{msg}" if @v
    end

    def errlog(msg)
      raise "ERROR: #{msg}"
    end

    def call
      resp = false
      EM.synchrony do
        begin
          resp = EventMachine::HttpRequest.new(url).get
        rescue StandardError => e
          #puts e.message + " ## " + url
          #the trap abrt is nescessary to handle the SSL error
          #for some ungodly reason it's the only way I found to handle it
          trap("ABRT"){
            puts "#{url} failed SSL Certification Verification"
          }
          return false
        end
        lg("URL Crawled: #{url}")
        EventMachine.stop
      end
      if resp.response == ""
        errlog("Domain is not working. Try the non-WWW version.")
      end
      return resp.response.encode('UTF-8', :invalid => :replace, :undef => :replace) #.force_encoding('UTF-8') #ran into issues
    end

    private
    attr_reader :url
  end
end
