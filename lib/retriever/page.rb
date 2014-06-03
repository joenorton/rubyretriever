module Retriever

  class Page

    HREF_CONTENTS_RE = Regexp.new(/\shref=['|"]([^\s][a-z0-9\.\/\:\-\%\+\?\!\=\&\,\:\;\~\_]+)['|"][\s|\W]/ix).freeze
    NONPAGE_EXT_RE = Regexp.new(/\.(?:css|js|png|gif|jpg|mp4|wmv|flv|mp3|wav|doc|txt|ico)/ix).freeze
    HTTP_RE = Regexp.new(/^http/i).freeze
    DUB_DUB_DUB_DOT_RE = Regexp.new(/^www\./i).freeze

    attr_reader :links, :parseInternal, :parseInternalVisitable, :parseFiles

    def initialize(source,t)
      @t = t
      @source = source
    end

    #recieves page source as string
    #returns array of unique href links
    def links
      return false if !@source
      @source.scan(HREF_CONTENTS_RE).map do |match|  #filter some malformed URLS that come in, this is meant to be a loose filter to catch all reasonable HREF attributes.
        link = match[0]
        Link.new(@t.host, link).path
      end.uniq
    end

    def parseInternal
      links.select{ |linky| (@t.host_re =~ linky) }
    end

    def parseInternalVisitable
      parseInternal.select{ |linky| (!(NONPAGE_EXT_RE =~linky)) }
    end

    def parseFiles
      links.select{ |linky| (@t.file_re =~ linky)}
    end

  end

end
