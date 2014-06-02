require 'open-uri'

module Retriever
  class Target
    HTTP_RE = Regexp.new(/^http/i).freeze
    DUB_DUB_DUB_DOT_RE = Regexp.new(/^www\./i).freeze
    attr_reader :host, :target, :host_re, :source
    def initialize(url)
      url = "http://#{url}" if (!(HTTP_RE =~ url))
      fail "Bad URL" if (!(/\./ =~ url))
      new_uri = URI(url)
      @target = new_uri.to_s
      @host = new_uri.host
      @host_re = Regexp.new(@host).freeze
    end

    def source
      resp = false
      begin
        resp = open(@target)
      rescue StandardError => e
        #puts e.message + " ## " + url
        #the trap abrt is nescessary to handle the SSL error
        #for some ungodly reason it's the only way I found to handle it
        trap("ABRT"){
          puts "#{@target} failed SSL Certification Verification"
        }
        return false
      end
      if (@target != resp.base_uri.to_s)
          fail "Domain redirecting to new host: #{resp.base_uri.to_s}" if (!(@host_re =~ resp.base_uri.to_s))
      end
      resp = resp.read
      if resp == ""
        fail "Domain is not working. Try the non-WWW version."
      end
      return resp.encode('UTF-8', :invalid => :replace, :undef => :replace) #.force_encoding('UTF-8') #ran into issues with some sites without forcing UTF8 encoding, and also issues with it. Not sure atm.
    end

  end
end
