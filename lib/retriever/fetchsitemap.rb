module Retriever
  #
  class FetchSitemap < Fetch
    # recieves target URL and RR options
    # returns an array of all unique pages found on the site
    def initialize(url, options)
      super
      @data = [@t.target]
      page_one = Retriever::Page.new(@t.source, @t)
      lg("URL Crawled: #{@t.target}")
      @link_stack = page_one.parse_internal_visitable
      errlog("Bad URL -- #{@t.target}") unless @link_stack
      lg("#{@link_stack.size - 1} links found")

      @link_stack.delete(@t.target)
      @linkStack = @linkStack.take(@maxPages) if @linkStack.size + 1 > @maxPages
      @data.concat(@link_stack)

      async_crawl_and_collect

      @data.sort_by! { |x| x.length } if @data.size > 1
      @data.uniq!
    end

    # produces valid XML sitemap based on page collection fetched.
    # Writes to current directory.
    def gen_xml
      f = File.open("sitemap-#{@t.host.split('.')[1]}.xml", 'w+')
      f << "<?xml version='1.0' encoding='UTF-8'?><urlset xmlns='http://www.sitemaps.org/schemas/sitemap/0.9'>"
        @data.each do |url|
          f << "<url><loc>#{url}</loc></url>"
        end
      f << '</urlset>'
      f.close
      puts '###############################'
      puts "File Created: sitemap-#{@t.host.split('.')[1]}.xml"
      puts "Object Count: #{@data.size}"
      puts '###############################'
      puts
    end
  end
end
