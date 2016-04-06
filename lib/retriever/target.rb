require 'open-uri'
require 'addressable/uri'

module Retriever
  #
  class Target
    HTTP_RE    = Regexp.new(/^http/i).freeze

    attr_reader :host, :target, :host_re, :source, :file_re, :scheme, :port

    def initialize(url, file_re = nil)
      fail 'Bad URL' unless url.include?('.')
      url         = "http://#{url}" unless HTTP_RE =~ url
      target_uri  = Addressable::URI.parse(Addressable::URI.encode(url))
      @target     = target_uri.to_s
      @host       = target_uri.host
      @host_re    = Regexp.new(@host.sub('www.', ''))
      @file_re  ||= file_re
      @scheme     = target_uri.scheme
      @port       = target_uri.port
    end

    def source
      resp = open(@target)
      resp_url = resp.base_uri.to_s
      if @target != resp_url
        fail "Domain redirecting: #{resp_url}" unless @host_re =~ resp_url
        # if redirect URL is same host, we want to re-sync @target
        return resync_target_and_return_source(resp_url)
      end
      resp = resp.read
      #
      fail 'Domain is not working. Try the non-WWW version.' if resp == ''
      fail 'Domain not working. Try HTTPS???' unless resp
      # consider using scrub from ruby 2.1? this misses some things
      resp.encode('UTF-8', 'binary', invalid: :replace, undef: :replace)
    end

    def resync_target_and_return_source(url)
      new_t   = Retriever::Target.new(url)
      @target = new_t.target
      @host   = new_t.host
      @scheme = new_t.scheme
      new_t.source
    end
  end
end
