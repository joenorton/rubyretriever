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

			self.dump(self.sitemap)
			self.write(self.sitemap) if /CSV/i =~ @s
			self.gen_xml(self.sitemap) if /XML/i =~ @s
		end
		def gen_xml(data)
			f = File.open("sitemap-#{@host.split('.')[1]}.xml", 'w+')
			f << "<?xml version='1.0' encoding='UTF-8'?><urlset xmlns='http://www.sitemaps.org/schemas/sitemap/0.9'>"
				data.each do |url|
					f << "<url><loc>#{url}</loc></url>"
				end
			f << "</urlset>"
			f.close
			puts "###############################"
			puts "File Created: sitemap-#{@host.split('.')[1]}.xml"
			puts "Object Count: #{@sitemap.size}"
			puts "###############################"
			puts
		end
	end
end