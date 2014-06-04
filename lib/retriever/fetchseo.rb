module Retriever
	class FetchSEO < Fetch
		attr_reader :seoStack
		def initialize(url,options)
			super
			@seoStack = []
			page_one = Retriever::Page.new(@t.source,@t)
			@linkStack = page_one.parseInternalVisitable
			lg("URL Crawled: #{@t.target}")
			lg("#{@linkStack.size-1} new links found")

			@seoStack.push(page_one.parseSEO)
			lg("#{@seoStack.size} pages scraped")
			errlog("Bad URL -- #{@t.target}") if !@linkStack

			@linkStack.delete(@t.target) if @linkStack.include?(@t.target)
			@linkStack = @linkStack.take(@maxPages) if (@linkStack.size+1 > @maxPages)

			async_crawl_and_collect()

			@seoStack.sort_by! {|x| x[0].length}

			dump(@seoStack)
			write(@seoStack) if @output
		end
	end
end