require 'open-uri'

module Retriever
  
  class Target
    
    HTTP_RE = Regexp.new(/^http/i).freeze
    DUB_DUB_DUB_DOT_RE = Regexp.new(/^www\./i).freeze
    
    attr_reader :host, :target, :host_re, :source, :file_re

    def initialize(url,file_re=nil)
      url = "http://#{url}" if (!(HTTP_RE =~ url))
      fail "Bad URL" if (!(/\./ =~ url))
      new_uri = URI(url)
      @target = new_uri.to_s
      @host = new_uri.host
      @host_re = Regexp.new(@host.sub('www.',''))
      @file_re ||= file_re
    end

    def source
      resp = false
      begin
        resp = open(@target)
      rescue StandardError => e
        trap("ABRT"){
          puts "#{@target} failed SSL Certification Verification"
        }
        return false
      end
      resp_url = resp.base_uri.to_s
      if (@target != resp_url)
          if @host_re =~ resp_url #if redirect URL is same hose, we want to re-sync our target with the right URL
            new_t = Retriever::Target.new(resp_url)
            @target = new_t.target
            @host = new_t.host
            return new_t.source
          end
          fail "Domain redirecting to new host: #{resp.base_uri.to_s}" #if it's not same host, we want to fail 
      end
      resp = resp.read
      if resp == ""
        fail "Domain is not working. Try the non-WWW version."
      end
      fail "Domain not working. Try HTTPS???" if !resp
      return resp.encode('UTF-8', 'binary', :invalid => :replace, :undef => :replace) #consider using scrub from ruby 2.1? this misses some things
    end

  end

end
