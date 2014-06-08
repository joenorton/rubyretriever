module Retriever
	class FetchSitemap < Fetch
		def initialize(url,options) #recieves target URL and RR options, returns an array of all unique pages found on the site
			super
			@data = [@t.target]
			page_one = Retriever::Page.new(@t.source,@t)
			@linkStack = page_one.parseInternalVisitable
			lg("URL Crawled: #{@t.target}")
			lg("#{@linkStack.size-1} new links found")
			errlog("Bad URL -- #{@t.target}") if !@linkStack

			@linkStack.delete(@t.target) if @linkStack.include?(@t.target)
			@linkStack = @linkStack.take(@maxPages) if (@linkStack.size+1 > @maxPages)
			@data.concat(@linkStack)

			self.async_crawl_and_collect()

			@data.sort_by!	 {|x| x.length} if @data.size>1
			@data.uniq!
		end
		def gen_xml #produces valid XML sitemap based on page collection fetched. Writes to current directory.
			f = File.open("sitemap-#{@t.host.split('.')[1]}.xml", 'w+')
			f << "<?xml version='1.0' encoding='UTF-8'?><urlset xmlns='http://www.sitemaps.org/schemas/sitemap/0.9'>"
				@data.each do |url|
					f << "<url><loc>#{url}</loc></url>"
				end
			f << "</urlset>"
			f.close
			puts "###############################"
			puts "File Created: sitemap-#{@t.host.split('.')[1]}.xml"
			puts "Object Count: #{@data.size}"
			puts "###############################"
			puts
		end
	end
end