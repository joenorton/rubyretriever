module Retriever
  #
  class Page
    HREF_CONTENTS_RE = Regexp.new(/\shref=['|"]([^\s][a-z0-9\.\/\:\-\%\+\?\!\=\&\,\:\;\~\_]+)['|"][\s|\W]/ix).freeze
    NONPAGE_EXT_RE = Regexp.new(/\.(?:css|js|png|gif|jpg|mp4|wmv|flv|mp3|wav|doc|txt|ico|xml)/ix).freeze
    HTTP_RE = Regexp.new(/^http/i).freeze
    DUB_DUB_DUB_DOT_RE = Regexp.new(/^www\./i).freeze

    TITLE_RE = Regexp.new(/<title>(.*)<\/title>/i).freeze
    DESC_RE = Regexp.new(/<meta[^>]*name=[\"|\']description[\"|\'][^>]*content=[\"]([^\"]*)[\"][^>]*>/i).freeze
    H1_RE = Regexp.new(/<h1>(.*)<\/h1>/i).freeze
    H2_RE = Regexp.new(/<h2>(.*)<\/h2>/i).freeze

    attr_reader :links, :source, :t

    def initialize(source, t)
      @t = t
      @source = source.encode('UTF-8', :invalid => :replace, :undef => :replace)
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
      end.uniq
    end

    def parse_internal
      links.select { |linky| (@t.host_re =~ linky) }
    end

    def parse_internal_visitable
      parse_internal.select { |linky| (!(NONPAGE_EXT_RE =~ linky)) }
    end

    def parse_files
      links.select { |linky| (@t.file_re =~ linky) }
    end

    def title
      TITLE_RE =~ @source ? @source.match(TITLE_RE)[1] : ''
    end

    def desc
      DESC_RE =~ @source ? @source.match(DESC_RE)[1] : ''
    end

    def h1
      H1_RE =~ @source ? @source.match(H1_RE)[1] : ''
    end

    def h2
      H2_RE =~ @source ? @source.match(H2_RE)[1] : ''
    end

    def parse_seo
      [title, desc, h1, h2]
    end
  end
end
