module Retriever
  #
  class FetchSEO < Fetch
    # recieves target url and RR options
    # returns an array of onpage SEO related fields
    #   on all unique pages found on the site
    def initialize(url, options)
      super
      @data.push(@page_one.parse_seo)

      async_crawl_and_collect
      # done, make sure progress bar says we are done
      @progressbar.finish if @progress
      @data.sort_by! { |x| x[0].length }
    end
  end
end
