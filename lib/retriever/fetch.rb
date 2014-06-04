require 'em-synchrony'
require 'em-synchrony/em-http'
require 'em-synchrony/fiber_iterator'
require 'ruby-progressbar'
require 'open-uri'
require 'csv'
require 'bloomfilter-rb'

module Retriever
	class Fetch
		attr_reader :maxPages, :t

		def initialize(url,options)
			#OPTIONS
			@prgrss = options[:progress] ? options[:progress] : false
			@maxPages = options[:maxpages] ? options[:maxpages].to_i : 100
			@v= options[:verbose] ? true : false
			@output=options[:filename] ? options[:filename] : false
			@fh = options[:fileharvest] ? options[:fileharvest] : false
			@file_ext = @fh.to_s
			@s = options[:sitemap] ? options[:sitemap] : false
			@seo = options[:seo] ? true : false
			@autodown = options[:autodown] ? true : false
			#
			if @fh
				tempExtStr = "."+@file_ext+'\z'
				@file_re = Regexp.new(tempExtStr).freeze
			else
				errlog("Cannot AUTODOWNLOAD when not in FILEHARVEST MODE") if @autodown #when FH is not true, and autodown is true
			end
			if @prgrss
				errlog("CANNOT RUN VERBOSE & PROGRESSBAR AT SAME TIME, CHOOSE ONE, -v or -p") if @v #verbose & progressbar conflict
				prgressVars = {
					:title => "Pages Crawled",
					:starting_at => 1,
					:total => @maxPages,
					:format => '%a |%b>%i| %c/%C %t',
				}
				@progressbar = ProgressBar.create(prgressVars)
			end
			@t = Retriever::Target.new(url,@file_re)
			@already_crawled = BloomFilter::Native.new(:size => 1000000, :hashes => 5, :seed => 1, :bucket => 8, :raise => false)
			@already_crawled.insert(@t.target)
			if (@fh && !output)
				@output = "rr-#{@t.host.split('.')[1]}"
			end
		end
		def errlog(msg)
			raise "ERROR: #{msg}"
		end
		def lg(msg)
			puts "### #{msg}" if @v
		end
		def dump(data)
			puts "###############################"
			if @s
				puts "#{@t.target} Sitemap"
				puts "Page Count: #{data.size}"
			elsif @fh
				puts "Target URL: #{@t.target}"
				puts "Filetype: #{@file_ext}"
				puts "File Count: #{data.size}"
			elsif @seo
				puts "#{@t.target} SEO Metrics"
				puts "Page Count: #{data.size}"
			else
				puts "ERROR"
			end
			puts "###############################"
			puts data
			puts "###############################"
			puts
		end
		def write(data)
			if @output
				CSV.open("#{@output}.csv", "w") do |csv|
				  data.each do |entry|
				  	csv << [entry]
				  end
				end
				puts "###############################"
				puts "File Created: #{@output}.csv"
				puts "Object Count: #{data.size}"
				puts "###############################"
				puts
			end
		end
		def async_crawl_and_collect()
			while (@already_crawled.size < @maxPages)
				if @linkStack.empty?
					if @prgrss
						@progressbar.log("Can't find any more links. Site might be completely mapped.")
					else
						lg("Can't find any more links. Site might be completely mapped.")
					end
					break;
				end
				new_links_arr = self.asyncGetWave()
				next if (new_links_arr.nil? || new_links_arr.empty?)
				new_link_arr = new_links_arr-@linkStack#set operations to see are these in our previous visited pages arr?
				@linkStack.concat(new_links_arr)
				@sitemap.concat(new_links_arr) if @s
			end
			@progressbar.finish if @prgrss
		end
		def asyncGetWave() #send a new wave of GET requests, using current @linkStack
			new_stuff = []
			EM.synchrony do
				lenny = 0
			    concurrency = 10
			    EM::Synchrony::FiberIterator.new(@linkStack, concurrency).each do |url|
			    	next if (@already_crawled.size >= @maxPages)
			    	if @already_crawled.include?(url)
			    		@linkStack.delete(url)
			    		next
			    	end
			    	resp = EventMachine::HttpRequest.new(url).get
			    	if !resp.response_header['CONTENT_TYPE'].include?("text/html") #if webpage is not text/html, let's not continue and lets also make sure we dont re-queue it
			    		@already_crawled.insert(url)
			    		@linkStack.delete(url)
			    		next
			    	end
			    	new_page = Retriever::Page.new(resp.response,@t)
					lg("URL Crawled: #{url}")
			    	@already_crawled.insert(url)
					if @prgrss
						@progressbar.increment if @already_crawled.size < @maxPages
					end
					if @seo
						seos = [url]
						seos.concat(new_page.parseSEO)
						@seoStack.push(seos)
						lg("#{@seoStack.size} pages scraped")
					end
					if new_page.links
						lg("#{new_page.links.size} new links found")
						internal_links_arr = new_page.parseInternalVisitable
						new_stuff.push(internal_links_arr)
						if @fh
							filez = new_page.parseFiles
							@fileStack.concat(filez) if !filez.empty?
							lg("#{filez.size} files found")
						end
					end
			    end
			    new_stuff = new_stuff.flatten # all completed requests
			    EventMachine.stop
			end
			new_stuff.uniq!
		end
	end
end