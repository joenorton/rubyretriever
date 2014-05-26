require 'retriever/page'

module Retriever
	class Fetch
		attr_reader :target, :host, :host_re, :maxPages
		#constants
		HTTP_RE = Regexp.new(/^http/i).freeze
		HREF_CONTENTS_RE = Regexp.new(/\shref=['|"]([^\s][a-z0-9\.\/\:\-\%\+\?\!\=\&\,\:\;\~\_]+)['|"][\s|\W]/ix).freeze
		NONPAGE_EXT_RE = Regexp.new(/\.(?:css|js|png|gif|jpg|mp4|wmv|flv|mp3|wav|doc|txt|ico)/ix).freeze
		SINGLE_SLASH_RE = Regexp.new(/^\/{1}[^\/]/).freeze
		DOUBLE_SLASH_RE = Regexp.new(/^\/{2}[^\/]/).freeze
		NO_SLASH_PAGE_RE = Regexp.new(/^[a-z0-9\-\_\=\?\.]+\z/ix).freeze
		DUB_DUB_DUB_DOT_RE = Regexp.new(/^www\./i).freeze

		def initialize(url,options)
			new_uri = URI(url)
			@target = new_uri.to_s
			@host = new_uri.host
			#OPTIONS
			@prgrss = options[:progress] ? options[:progress] : false
			@maxPages = options[:maxpages] ? options[:maxpages].to_i : 100
			@v= options[:verbose] ? true : false
			@output=options[:filename] ? options[:filename] : false
			@fh = options[:fileharvest] ? true : false
			@s = options[:sitemap] ? true : false
			@file_ext = options[:file_ext] ? options[:file_ext] : false
			@autodown = options[:autodown] ? true : false
			#
			@host_re = Regexp.new(host).freeze
			if @fh
				errlog("Please provide a FILETYPE. It is required for file harvest mode.") if !@file_ext
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
			@already_crawled = BloomFilter::Native.new(:size => 1000000, :hashes => 5, :seed => 1, :bucket => 8, :raise => false)
			@already_crawled.insert(@target)
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
				puts "#{@target} Sitemap"
				puts "Page Count: #{data.size}"
			elsif @fh
				puts "Target URL: #{@target}"
				puts "Filetype: #{@file_ext}"
				puts "File Count: #{data.size}"
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
				puts "File Created: #{filename}.csv"
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
				#puts "New loop"
				#puts @linkStack
				new_links_arr = self.asyncGetWave()
				next if (new_links_arr.nil? || new_links_arr.empty?)
				new_link_arr = new_links_arr-@linkStack#set operations to see are these in our previous visited pages arr?
				@linkStack.concat(new_links_arr)
				@sitemap.concat(new_links_arr) if @s
			end
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
			    	else
			    		@already_crawled.insert(url)
			    	end
			    	resp = EventMachine::HttpRequest.new(url).get
					lg("URL Crawled: #{url}")
					if @prgrss
						@progressbar.increment if @already_crawled.size < @maxPages
					end
					new_links_arr = self.fetchLinks(resp.response)
					if new_links_arr
						lg("#{new_links_arr.size} new links found")
						internal_links_arr = self.parseInternalLinks(new_links_arr)
						new_stuff.push(internal_links_arr)
						if @fh
							filez = self.parseFiles(new_links_arr)
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

		def parseFiles(all_links)
			all_links.select{ |linky| (@file_re =~ linky)}
		end
	end
end
