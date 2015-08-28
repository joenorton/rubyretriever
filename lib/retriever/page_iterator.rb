module Retriever
  #
  class PageIterator < Fetch
    # receives target url and RR options, and a block
    # runs the block on all pages during crawl, pushing
    #   the returned value of the block onto a result stack
    #   the complete data returned from the crawl is accessible thru self.result
    def initialize(url, options, &block)
      super
      start
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
