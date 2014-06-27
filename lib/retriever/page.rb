require 'addressable/uri'
#
using SourceString
module Retriever
  #
  class Page
    HTTP_RE   = Regexp.new(/^http/i).freeze
    H1_RE     = Regexp.new(/<h1>(.*)<\/h1>/i).freeze
    H2_RE     = Regexp.new(/<h2>(.*)<\/h2>/i).freeze
    TITLE_RE  = Regexp.new(/<title>(.*)<\/title>/i).freeze
    DESC_RE   = Regexp.new(/<meta[^>]*name=[\"|\']description[\"|\']
                          [^>]*content=[\"]
                          (
                            [^\"]*
                          )
                          [\"]
                          [^>]
                          *>
                          /ix).freeze
    HREF_CONTENTS_RE = Regexp.new(/\shref=
                                  ['|"]
                                  (
                                    [^\s]
                                    [a-z0-9\.\/\:\-\%\+\?\!\=\&\,\:\;\~\_]+
                                  )
                                  ['|"]
                                  [\s|\W]
                                  /ix).freeze
    NONPAGE_EXT_RE = Regexp.new(/\.
                                (?:css|js|png|gif|jpg|mp4|
                                wmv|flv|mp3|wav|doc|txt|ico|xml)
                                /ix).freeze

    attr_reader :links, :source, :t, :url

    def initialize(url, source, t)
      @url = url
      @t = t
      @source = source.encode_utf8_and_replace
      @links = nil
    end

    # recieves page source as string
    # returns array of unique href links
    def links
      return @links if @links
      return false unless @source
      @links = @source.scan(HREF_CONTENTS_RE).map do |match|
        # filter some malformed URLS that come in
        # meant to be a loose filter to catch all reasonable HREF attributes.
        link = match[0]
        Link.new(@t.scheme, @t.host, link).path
      end.compact.uniq
    end

    def parse_internal
      links.select do |x|
        @t.host == Addressable::URI.parse(Addressable::URI.encode(x)).host
      end
    end

    def parse_internal_visitable
      parse_internal.select { |x| !(NONPAGE_EXT_RE =~ x) }
    end

    def parse_files(arr = parse_internal)
      arr.select { |x| @t.file_re =~ x }
    end

    def title
      TITLE_RE =~ @source ? @source.match(TITLE_RE)[1].decode_html : ''
    end

    def desc
      DESC_RE =~ @source ? @source.match(DESC_RE)[1].decode_html  : ''
    end

    def h1
      H1_RE =~ @source ? @source.match(H1_RE)[1].decode_html  : ''
    end

    def h2
      H2_RE =~ @source ? @source.match(H2_RE)[1].decode_html  : ''
    end

    def parse_seo
      [title, desc, h1, h2]
    end
  end
end
