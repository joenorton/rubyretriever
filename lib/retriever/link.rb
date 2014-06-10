module Retriever
  #
  class Link
    HTTP_RE = Regexp.new(/^http/i).freeze
    SINGLE_SLASH_RE = Regexp.new(/^\/{1}[^\/]/).freeze
    DOUBLE_SLASH_RE = Regexp.new(/^\/{2}[^\/]/).freeze
    NO_SLASH_PAGE_RE = Regexp.new(/^[a-z0-9\-\_\=\?\.]+\z/ix).freeze
    DUB_DUB_DUB_DOT_RE = Regexp.new(/^www\./i).freeze

    def initialize(host, link)
      @host = host
      @link = link
    end

    def path
      return link if HTTP_RE =~ link

      return "http://#{link}" if DUB_DUB_DUB_DOT_RE =~ link

      return "http://#{host}#{link}" if SINGLE_SLASH_RE =~ link

      # link begins with '//'
      return "http:#{link}" if DOUBLE_SLASH_RE =~ link

      # link uses relative path with no slashes at all
      return "http://#{host}/#{link}" if NO_SLASH_PAGE_RE =~ link
    end

    private

    attr_reader :host, :link
  end
end
