module Retriever
	class FetchSEO < Fetch
		def initialize(url,options) #recieves target url and RR options, returns an array of onpage SEO related fields on all unique pages found on the site
			super
			@data = []
			page_one = Retriever::Page.new(@t.source,@t)
			@linkStack = page_one.parseInternalVisitable
			lg("URL Crawled: #{@t.target}")
			lg("#{@linkStack.size-1} new links found")

			@data.push(page_one.parseSEO)
			lg("#{@data.size} pages scraped")
			errlog("Bad URL -- #{@t.target}") if !@linkStack

			@linkStack.delete(@t.target) if @linkStack.include?(@t.target)
			@linkStack = @linkStack.take(@maxPages) if (@linkStack.size+1 > @maxPages)

			self.async_crawl_and_collect()

			@data.sort_by! {|x| x[0].length}
		end
	end
end