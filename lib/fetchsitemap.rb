module Retriever
	class FetchSitemap < Fetch
		attr_reader :sitemap
		def initialize(url,options)
			super
			@sitemap = [@target]
			@linkStack = self.parseInternalLinks(self.fetchLinks(fetchPage(@target)))
			self.lg("#{@linkStack.size-1} new links found")
			errlog("Bad URL -- #{@target}") if !@linkStack

			@linkStack.delete(@target) if @linkStack.include?(@target)
			@linkStack = @linkStack.take(@maxPages) if (@linkStack.size+1 > @maxPages)
			@sitemap.concat(@linkStack)

			self.async_crawl_and_collect()

			@sitemap.sort_by!	 {|x| x.length} if @sitemap.size>1
			@sitemap.uniq!
			@sitemap = @sitemap.take(@maxPages) if (@sitemap.size+1 > @maxPages)

			@progressbar.finish if @prgrss
			self.dump(self.sitemap)
			self.write(@output,self.sitemap) if @output
		end
	end
end