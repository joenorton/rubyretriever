module Retriever
  #
  class CLI
    def initialize(url, options)
      # kick off the fetch mode of choice
      if options['fileharvest']
        @fetch = Retriever::FetchFiles.new(url, options)
      elsif options['sitemap']
        @fetch = Retriever::FetchSitemap.new(url, options)
      elsif options['seo']
        @fetch = Retriever::FetchSEO.new(url, options)
      else
        fail '### Error: No Mode Selected'
      end
      @fetch.dump
      @fetch.write if options['filename']
      @fetch.autodownload if options['autodown'] && options['fileharvest']
      @fetch.gen_xml if /XML/i =~ options['sitemap'].to_s
    end
  end
end
