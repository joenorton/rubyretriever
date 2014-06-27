require 'addressable/uri'
module Retriever
  #
  class Link
    # HTTP_RE = Regexp.new(/^http/i).freeze
    SLASH_RE = Regexp.new(%r(^/{1}[^/])).freeze
    DOUBLE_SLASH_RE = Regexp.new(%r(^/{2}[^/])).freeze
    WWW_DOT_RE = Regexp.new(/^www\./i).freeze

    def initialize(target_scheme, target_host, this_link)
      begin
        this_link = Addressable::URI.encode(this_link)
        @link_uri = Addressable::URI.parse(this_link)
      rescue Addressable::URI::InvalidURIError
        dummy = Retriever::Link.new(target_scheme, target_host, target_host)
        @link_uri = Addressable::URI.parse(dummy.path)
      end
      @scheme = target_scheme
      @host = target_host
      @this_link = @link_uri.to_s
    end

    def path
      return this_link if link_uri.absolute?

      return "#{@scheme}://#{this_link}" if WWW_DOT_RE =~ this_link

      return "#{@scheme}://#{host}#{this_link}" if SLASH_RE =~ this_link

      # link begins with '//'
      return "#{@scheme}:#{this_link}" if DOUBLE_SLASH_RE =~ this_link

      # link uses relative path with no slashes at all
      return "#{@scheme}://#{host}/#{this_link}" if link_uri.relative?
    end

    private

    attr_reader :this_link, :host, :link_uri
  end
end
