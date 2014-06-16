require 'retriever'
#
module Retriever
  #
  class PageIterator < Fetch
    # recieves target url and RR options
    # returns an array of onpage SEO related fields
    #   on all unique pages found on the site
    def initialize(url, options, &block)
      super
      fail 'block required for PageIterator' unless block_given?
      @iterator = true
      @result.push(block.call @page_one)
      lg("-- PageIterator crawled- #{url}")
      async_crawl_and_collect(&block)
      # done, make sure progress bar says we are done
      @progressbar.finish if @progress
      @result.sort_by! { |x| x.length } if @result.size > 1
    end
  end
end
