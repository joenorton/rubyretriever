module Retriever
  #
  class FetchSEO < Fetch
    # receives target url and RR options
    # returns an array of onpage SEO related fields
    #   on all unique pages found on the site
    def initialize(url, options)
      super
      start
      @result.push(@page_one.parse_seo)

      async_crawl_and_collect
      # done, make sure progress bar says we are done
      @progressbar.finish if @progress
      @result.sort_by! { |x| x[0].length }
    end
  end
end
