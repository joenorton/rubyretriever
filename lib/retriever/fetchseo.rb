module Retriever
  #
  class FetchSEO < Fetch
    # recieves target url and RR options
    # returns an array of onpage SEO related fields
    #   on all unique pages found on the site
    def initialize(url, options)
      super
      @data = []
      page_one = Retriever::Page.new(@t.source, @t)
      lg("URL Crawled: #{@t.target}")

      @link_stack = page_one.parse_internal_visitable
      errlog("Bad URL -- #{@t.target}") unless @link_stack
      lg("#{@link_stack.size - 1} links found")
      @link_stack.delete(@t.target)

      @data.push(page_one.parse_seo)

      async_crawl_and_collect

      @data.sort_by! { |x| x[0].length }
    end
  end
end
