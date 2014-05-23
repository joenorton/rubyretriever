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
			PAGE_EXT_RE = Regexp.new(/\.(?:css|js|png|gif|jpg|mp4|wmv|flv|mp3|wav|doc|txt)\z/i).freeze
			def initialize(url,options)
				@start_time = Time.now
				new_uri = URI(url)
				@target = new_uri.to_s
				@host = new_uri.host
				if options.empty?
					@maxPages = 1000
					@v = false
					@output = false
				else
					@maxPages=options[:maxpages].to_i if options[:maxpages]
					@v=true if options[:verbose]
					@output=options[:filename] if options[:filename]
				end
				@host_re = Regexp.new(host).freeze
			end
			def errlog(msg)
				raise "ERROR: #{msg}"
			end
			def lg(msg)
				puts "### #{msg}"
			end
			def dump(data)
				puts data
				puts "###############################"
				puts "Data Dump: "
				puts "Object Count: #{data.size}"
				puts "###############################"
				puts
			end
			def write(filename,data)
				CSV.open("#{filename}.csv", "w") do |csv|
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
			def fetchDoc(url)
				return false if !url
				begin
					#grab site into Nokogiri object
					doc = open(url,'User-Agent' => 'Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; Trident/6.0)', :read_timeout=>5).read
					#doc = Nokogiri::HTML(open(url,'User-Agent' => 'Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; Trident/6.0)', :read_timeout=>5))
				rescue StandardError => e
					#puts e.message + " ## " + url
					#the trap abrt is nescessary to handle the SSL error
					#for some ungodly reason it's the only way I found to handle it
					trap("ABRT"){
						puts "#{url} failed SSL Certification Verification"
					}
					return false
				end
				return doc
			end
			def fetchLinks(doc,url)
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
							if /\/\z/ =~ url #when url ends with slash we have to trim it when appending the new path	
								url = url[0..-2]
							end
							link = url+link #appending current url to relative paths
						elsif /^\/{2}[^\/]/ =~ link #link uses relative path
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
			def parseInternalLinks(all_links,host_re)
				all_links.select{ |linky| (host_re =~ linky && (!(PAGE_EXT_RE =~linky)))}
			end
			def crawl_site_collect_links(stack,collection,limit,host_re)
				current_size = collection.size
				while (stack.size > 0 && current_size < limit)
					stack.each do |url|
						break if (current_size+1 > limit)
						doc = fetchDoc(url)
						next if !doc
						lg("URL Crawled: #{url}") if @v
						linkx = fetchInternalLinks(doc,url,host_re)
						next if linkx.empty?
						new_links_arr = linkx - collection #set operations to see are these in our previous visited pages arr?
						 if !new_links_arr.empty?
						 	stack.concat(new_links_arr)
							collection.concat(new_links_arr)
							lg("#{new_links_arr.size} new links found") if @v
							current_size += new_links_arr.size
						end
					end
					collection.sort_by! {|x| x.length}
				end
			end
			def crawl_and_collect(stack,collection,already_crawled,limit,host_re,file_ext_re,v)
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
						doc = fetchDoc(url)
						next if !doc
						if simple
							next if collection.include?(url)
							collection.push(url)
						else
							next if already_crawled.include?(url)
							already_crawled.push(url)
						end
						lg("URL Crawled: #{url}") if v
						lnks = fetchLinks(doc,url)
						if !simple
							filez = parseFiles(lnks,file_ext_re)
							collection.concat(filez) if !filez.empty?
							lg("#{filez.size} files found") if v
						end
						current_size += 1
						linkx = parseInternalLinks(lnks,host_re)
						next if linkx.empty?
						if simple
							new_links_arr = linkx-collection
						else
							new_links_arr = linkx-already_crawled
						end#set operations to see are these in our previous visited pages arr?
						stack.concat(new_links_arr) if !new_links_arr.empty?
						if simple
							collection.concat(new_links_arr)
							lg("#{new_links_arr.size} new links found") if v
							current_size += new_links_arr.size
						end
					end
				end
				collection.uniq!
				return collection.sort_by {|x| x.length} if collection.size>1
			end
			def async_crawl_and_collect(stack,collection,already_crawled,limit,host_re,file_ext_re,v)
				current_size = collection.size
				while (stack.size > 0 && current_size < limit)
					new_links_arr = asyncGetWave(stack,v)
					next if new_links_arr.empty?
					new_links_arr = new_links_arr-collection #set operations to see are these in our previous visited pages arr?
					stack.concat(new_links_arr)
					collection.concat(new_links_arr)
					current_size += new_links_arr.size
				end
				collection.uniq!
				return collection.sort_by {|x| x.length} if collection.size>1
			end
			def asyncGetWave(link_arr,v)
				new_stuff = []
				EM.synchrony do
					lenny = 0
				    concurrency = 10
				    urls = link_arr
				    results = []
				    # iterator will execute async blocks until completion, .each, .inject also work!
				     EM::Synchrony::FiberIterator.new(urls, concurrency).each do |url|
				       resp = EventMachine::HttpRequest.new(url).get
				       lg("URL Crawled: #{url}") if v
				       new_links_arr = parseInternalLinks(fetchLinks(resp.response,url),@host_re)
				       	lg("#{new_links_arr.size} new links found") if v
				    	results.push(new_links_arr)
				    end
				    new_stuff = results.flatten # all completed requests
				    EventMachine.stop
				end
				new_stuff.uniq!
			end
		end
	class FetchFiles < Fetch
		attr_reader :fileStack
		def initialize(url,options)
			super	
			puts "ok"
			@fileStack = []
			@file_ext = options[:file_ext]
			tempExtStr = "."+@file_ext+'\z'
			@file_re = Regexp.new(tempExtStr).freeze
			@already_crawled = [@target]
			doc = fetchDoc(@target)
			all_links = fetchLinks(doc,@target)
			@linkStack = parseInternalLinks(all_links,@host_re)
			lg("#{@linkStack.size-1} new links found") if @v
			tempFileCollection = parseFiles(all_links,@file_re)
			@fileStack.concat(tempFileCollection) if tempFileCollection.size>0
			lg("#{@fileStack.size} new files found") if @v
			errlog("Bad URL -- #{@target}") if !@linkStack
			@linkStack.delete(@target) if @linkStack.include?(@target)
			@linkStack = @linkStack.take(@maxPages) if (@linkStack.size+1 > @maxPages)
			crawl_and_collect(@linkStack,@fileStack,@already_crawled,@maxPages,@host_re,@file_re,@v)
			lg("DONE - elapsed time: #{Time.now-@start_time} seconds")
			self.dump(self.fileStack) if @v
		end
		def parseFiles(all_links,file_re)
			all_links.select{ |linky| (file_re =~ linky)}
		end
	end
	class FetchSitemap < Fetch
		attr_reader :sitemap
		def initialize(url,options)
			super
			@sitemap = [@target]
			@linkStack = parseInternalLinks(fetchLinks(fetchDoc(@target),@target),@host_re)
			lg("#{@linkStack.size-1} new links found") if @v
			errlog("Bad URL -- #{@target}") if !@linkStack
			@linkStack.delete(@target) if @linkStack.include?(@target)
			@linkStack = @linkStack.take(@maxPages) if (@linkStack.size+1 > @maxPages)
			@sitemap.concat(@linkStack)
			async_crawl_and_collect(@linkStack,@sitemap,'',@maxPages,@host_re,'',@v)
			@sitemap = @sitemap.take(@maxPages) if (@sitemap.size+1 > @maxPages)
			lg("DONE - elapsed time: #{Time.now-@start_time} seconds")
			self.dump(self.sitemap) if @v
			#self.write(@output,self.sitemap) if @output
		end
	end
end