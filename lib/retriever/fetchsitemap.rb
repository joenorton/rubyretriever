module Retriever
	class FetchSitemap < Fetch
		attr_reader :sitemap
		def initialize(url,options)
			super
			@sitemap = [@t.target]
			page_one = Retriever::Page.new(@t.source,@t)
			@linkStack = page_one.parseInternalVisitable
			lg("URL Crawled: #{@t.target}")
			self.lg("#{@linkStack.size-1} new links found")
			errlog("Bad URL -- #{@t.target}") if !@linkStack

			@linkStack.delete(@t.target) if @linkStack.include?(@t.target)
			@linkStack = @linkStack.take(@maxPages) if (@linkStack.size+1 > @maxPages)
			@sitemap.concat(@linkStack)

			async_crawl_and_collect()

			@sitemap.sort_by!	 {|x| x.length} if @sitemap.size>1
			@sitemap.uniq!

			dump(@sitemap)
			write(@sitemap) if /CSV/i =~ @s
			gen_xml(@sitemap) if /XML/i =~ @s
		end
		def gen_xml(data)
			f = File.open("sitemap-#{@t.host.split('.')[1]}.xml", 'w+')
			f << "<?xml version='1.0' encoding='UTF-8'?><urlset xmlns='http://www.sitemaps.org/schemas/sitemap/0.9'>"
				data.each do |url|
					f << "<url><loc>#{url}</loc></url>"
				end
			f << "</urlset>"
			f.close
			puts "###############################"
			puts "File Created: sitemap-#{@t.host.split('.')[1]}.xml"
			puts "Object Count: #{@sitemap.size}"
			puts "###############################"
			puts
		end
	end
end