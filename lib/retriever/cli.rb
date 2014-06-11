module Retriever
  #
  class CLI
    def initialize(url, options)
      # kick off the fetch mode of choice
      @fetch = choose_fetch_mode(url, options)
      @fetch.dump
      @fetch.write if options['filename']
      @fetch.autodownload if options['autodown'] && options['fileharvest']
      @fetch.gen_xml if /XML/i =~ options['sitemap'].to_s
    end

    def choose_fetch_mode(url, options)
      if options['fileharvest']
        Retriever::FetchFiles.new(url, options)
      elsif options['sitemap']
        Retriever::FetchSitemap.new(url, options)
      elsif options['seo']
        Retriever::FetchSEO.new(url, options)
      else
        fail '### Error: No Mode Selected'
      end
    end
  end
end
