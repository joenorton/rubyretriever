##################################################################
#####RubyRetriever -- web crawler and file harvester
#####created by Joe Norton
#####http://softwarebyjoe.com
##LICENSING: GNU GPLv3  License##################################
#! usr/bin/ruby
#require 'nokogiri'
require 'open-uri'
require 'optparse'
require 'uri'
require 'csv'
require 'time'
require "em-synchrony"
require "em-synchrony/em-http"
require "em-synchrony/fiber_iterator"

require_relative('openuri_patch.rb')
require_relative('file_processor.rb')

module Retriever
		class Fetch
			attr_reader :target, :host, :host_re
			#constants
			LINK_RE = Regexp.new(/\shref=['|"]([^\s][a-z0-9\.\/\:\-\%\+\?\!\=\&\,\:\;\~]+)['|"][\s|\W]/ix).freeze
			PAGE_EXT_RE = Regexp.new(/\.(?:css|js|png|gif|jpg|mp4|wmv|flv|mp3|wav|doc|txt)/ix).freeze
			def initialize(url,options)
				@start_time = Time.now
				new_uri = URI(url)
				@target = new_uri.to_s
				@host = new_uri.host
				if options.empty?
					@maxPages = 1000
					@v = false
					@output = false
					@fh = false
					@s = true
					@file_ext = false
				else
					@maxPages=options[:maxpages].to_i if options[:maxpages]
					@v=true if options[:verbose]
					@output=options[:filename] if options[:filename]
					@fh=true if options[:fileharvest]
					@s=true if options[:sitemap]
					@file_ext = options[:file_ext] if options[:file_ext]
				end
				@host_re = Regexp.new(host).freeze
				if @fh
					tempExtStr = "."+@file_ext+'\z'
					@file_re = Regexp.new(tempExtStr).freeze
				end
			end
			def errlog(msg)
				raise "ERROR: #{msg}"
			end
			def lg(msg)
				puts "### #{msg}" if @v
			end
			def dump(data)
				puts data
				puts "###############################"
				puts "Data Dump: "
				puts "Object Count: #{data.size}"
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
				return resp.response
			end
			def fetchLinks(doc)
				return false if !doc
				#recieves nokogiri doc object, and string query
				#returns array of links
				linkArray = []
				doc.scan(LINK_RE) do |arr|
					#filter some malformed URLS that come in
					link = arr[0]
					if (!(/^http/ =~ link))
						if (/^www\./ =~ link)
							link = "http://#{link}"
						elsif /^\/{1}[^\/]/ =~ link #link uses relative path
							link = "http://#{@host}"+link #appending hostname to relative paths
						elsif /^\/{2}[^\/]/ =~ link #link begins with '//' (maybe a messed up link?)
							link = "http:#{link}" #appending current url to relative paths
						else
							next
						end
					end
					linkArray.push(link)
				end
				linkArray.uniq!
				return linkArray
			end
			def parseInternalLinks(all_links)
				if all_links
					all_links.select{ |linky| (@host_re =~ linky && (!(PAGE_EXT_RE =~linky)))}
				end
			end
			def crawl_site_collect_links(stack,collection)
				current_size = collection.size
				while (stack.size > 0 && current_size < limit)
					stack.each do |url|
						break if (current_size+1 > limit)
						doc = fetchPage(url)
						next if !doc
						lg("URL Crawled: #{url}")
						linkx = self.fetchInternalLinks(doc)
						next if linkx.empty?
						new_links_arr = linkx - collection #set operations to see are these in our previous visited pages arr?
						 if !new_links_arr.empty?
						 	stack.concat(new_links_arr)
							collection.concat(new_links_arr)
							lg("#{new_links_arr.size} new links found")
							current_size += new_links_arr.size
						end
					end
					collection.sort_by! {|x| x.length}
				end
			end
			def crawl_and_collect(collection)
				if already_crawled === '' 
					simple = true 
					current_size = collection.size
				else 
					simple = false
					current_size = already_crawled.size
				end
				while (stack.size > 0 && current_size < limit)
					stack.each do |url|
						break if (current_size+1 > limit)
						doc = fetchPage(url)
						next if !doc
						if simple
							next if collection.include?(url)
							collection.push(url)
						else
							next if already_crawled.include?(url)
							already_crawled.push(url)
						end
						lg("URL Crawled: #{url}")
						lnks = self.fetchLinks(doc,host)
						if !simple
							filez = self.parseFiles(lnks,file_ext_re)
							collection.concat(filez) if !filez.empty?
							lg("#{filez.size} files found")
						end
						current_size += 1
						linkx = self.parseInternalLinks(lnks)
						next if linkx.empty?
						if simple
							new_links_arr = linkx-collection
						else
							new_links_arr = linkx-already_crawled
						end#set operations to see are these in our previous visited pages arr?
						stack.concat(new_links_arr) if !new_links_arr.empty?
						if simple
							collection.concat(new_links_arr)
							lg("#{new_links_arr.size} new links found")
							current_size += new_links_arr.size
						end
					end
				end
				collection.uniq!
				return collection.sort_by {|x| x.length} if collection.size>1
			end
			def async_crawl_and_collect(collection)
				current_size = collection.size
				while (@linkStack.size > 0 && current_size < @maxPages)
					new_links_arr = self.asyncGetWave() if @s
					new_links_arr = self.asyncFHGetWave() if @fh
					next if new_links_arr.empty?
					new_links_arr = new_links_arr-collection #set operations to see are these in our previous visited pages arr?
					@linkStack.concat(new_links_arr)
					collection.concat(new_links_arr) if @s
					current_size += new_links_arr.size
				end
				if @s
					collection.uniq!
					return collection.sort_by {|x| x.length} if collection.size>1
				end
			end
			def asyncGetWave()
				new_stuff = []
				EM.synchrony do
					lenny = 0
				    concurrency = 10
				    results = []
				    # iterator will execute async blocks until completion, .each, .inject also work!
				    EM::Synchrony::FiberIterator.new(@linkStack, concurrency).each do |url|
				    	resp = EventMachine::HttpRequest.new(url).get
						lg("URL Crawled: #{url}")
						new_links_arr = self.parseInternalLinks(self.fetchLinks(resp.response))
						lg("#{new_links_arr.size} new links found")
						results.push(new_links_arr)
				    end
				    new_stuff = results.flatten # all completed requests
				    EventMachine.stop
				end
				new_stuff.uniq!
			end
			def asyncFHGetWave()
				new_stuff = []
				EM.synchrony do
					lenny = 0
				    concurrency = 10
				    results = []
				    # iterator will execute async blocks until completion, .each, .inject also work!
				    EM::Synchrony::FiberIterator.new(@linkStack, concurrency).each do |url|
				    	resp = EventMachine::HttpRequest.new(url).get
						lg("URL Crawled: #{url}")
						new_links_arr = self.fetchLinks(resp.response)
						lg("#{new_links_arr.size} new links found")
						internal_links_arr = self.parseInternalLinks(new_links_arr)
						filez = self.parseFiles(new_links_arr)
						@fileStack.concat(filez) if !filez.empty?
						lg("#{filez.size} files found")
						results.push(internal_links_arr)
				    end
				    new_stuff = results.flatten # all completed requests
				    EventMachine.stop
				end
				new_stuff.uniq!
			end
			def parseFiles(all_links)
				all_links.select{ |linky| (@file_re =~ linky)}
			end
		end
	class FetchFiles < Fetch
		attr_reader :fileStack
		def initialize(url,options)
			super	
			@fileStack = []
			@already_crawled = [@target]
			doc = fetchPage(@target)
			all_links = self.fetchLinks(doc)
			@linkStack = self.parseInternalLinks(all_links)
			self.lg("#{@linkStack.size-1} new links found")
			tempFileCollection = self.parseFiles(all_links)
			@fileStack.concat(tempFileCollection) if tempFileCollection.size>0
			self.lg("#{@fileStack.size} new files found")
			errlog("Bad URL -- #{@target}") if !@linkStack
			@linkStack.delete(@target) if @linkStack.include?(@target)
			#@linkStack = @linkStack.take(@maxPages) if (@linkStack.size+1 > @maxPages)
			self.async_crawl_and_collect(@fileStack)
			@fileStack.uniq!
			self.lg("DONE - elapsed time: #{Time.now-@start_time} seconds")
			self.dump(self.fileStack) if @v
		end
	end
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
			self.async_crawl_and_collect(@sitemap)
			@sitemap = @sitemap.take(@maxPages) if (@sitemap.size+1 > @maxPages)
			self.lg("DONE - elapsed time: #{Time.now-@start_time} seconds")
			self.dump(self.sitemap) if @v
			self.write(@output,self.sitemap) if @output
		end
	end
end