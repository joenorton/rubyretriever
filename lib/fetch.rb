module Retriever
	class Fetch
		attr_reader :target, :host, :host_re, :maxPages
		#constants
		HTTP_RE = Regexp.new(/^http/i).freeze
		HREF_CONTENTS_RE = Regexp.new(/\shref=['|"]([^\s][a-z0-9\.\/\:\-\%\+\?\!\=\&\,\:\;\~\_]+)['|"][\s|\W]/ix).freeze
		PAGE_EXT_RE = Regexp.new(/\.(?:css|js|png|gif|jpg|mp4|wmv|flv|mp3|wav|doc|txt|ico)/ix).freeze
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
				errlog("Cannot AUTODOWNLOAD when not in FILEHARVEST MODE") if @autodown
			end
			if @prgrss
				errlog("CANNOT RUN VERBOSE & PROGRESSBAR AT SAME TIME, CHOOSE ONE, -v or -p") if @v
				prgressVars = {
					:title => "Pages Crawled",
					:starting_at => 1,
					:total => @maxPages,
					:format => '%a |%b>%i| %c/%C %t',
				}
				@progressbar = ProgressBar.create(prgressVars)
			end
			@already_crawled = [@target]
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
		def fetchPage(url)
			resp = false
			EM.synchrony do
				begin
					resp = EventMachine::HttpRequest.new(url).get
				rescue StandardError => e
					#puts e.message + " ## " + url
					#the trap abrt is nescessary to handle the SSL error
					#for some ungodly reason it's the only way I found to handle it
					trap("ABRT"){
						puts "#{url} failed SSL Certification Verification"
					}
					return false
				end
				lg("URL Crawled: #{url}")
		    	EventMachine.stop
			end
			if resp.response == ""
				errlog("Domain is not working. Try the non-WWW version.")
			end
			return resp.response #.force_encoding('UTF-8') #ran into issues with some sites without forcing UTF8 encoding
		end
		def fetchLinks(doc)
			return false if !doc
			#recieves nokogiri doc object, and string query
			#returns array of links
			linkArray = []
			doc.scan(HREF_CONTENTS_RE) do |arr|  #filter some malformed URLS that come in, this is meant to be a loose filter to catch all reasonable HREF attributes.
				link = arr[0]
				if (!(HTTP_RE =~ link))
					if (DUB_DUB_DUB_DOT_RE =~ link)
						link = "http://#{link}"
					elsif SINGLE_SLASH_RE =~ link #link uses relative path
						link = "http://#{@host}"+link #appending hostname to relative paths
					elsif DOUBLE_SLASH_RE =~ link #link begins with '//' (maybe a messed up link?)
						link = "http:#{link}" #appending current url to relative paths
					elsif (NO_SLASH_PAGE_RE =~ link) #link uses relative path with no slashes at all, people actually this - imagine that.
						link = "http://#{@host}"+"/"+link #appending hostname and slashy to create full paths
					else
						next
					end
				end
				linkArray.push(link)
			end
			linkArray.uniq!
		end
		def parseInternalLinks(all_links)
			if all_links
				all_links.select{ |linky| (@host_re =~ linky && (!(PAGE_EXT_RE =~linky)))}
			else
				return false
			end
		end
		def async_crawl_and_collect()
			while (@linkStack.size > 0 && @already_crawled.size < @maxPages)
				new_links_arr = self.asyncGetWave()
				next if (new_links_arr.nil? || new_links_arr.empty?)
				new_link_arr = new_links_arr-@already_crawled-@linkStack#set operations to see are these in our previous visited pages arr?
				@linkStack.concat(new_links_arr)
				@sitemap.concat(new_links_arr) if @s
			end
		end
		def asyncGetWave()
			new_stuff = []
			EM.synchrony do
				lenny = 0
			    concurrency = 10
			    # iterator will execute async blocks until completion, .each, .inject also work!
			    EM::Synchrony::FiberIterator.new(@linkStack, concurrency).each do |url|
			    	if @already_crawled.include?(url)
			    		@linkStack.delete(url)
			    		next
			    	end
			    	next if (@already_crawled.size >= @maxPages)
			    	resp = EventMachine::HttpRequest.new(url).get
					lg("URL Crawled: #{url}")
					if @prgrss
						@progressbar.increment if @already_crawled.size < @maxPages
					end
					@already_crawled.push(url)
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