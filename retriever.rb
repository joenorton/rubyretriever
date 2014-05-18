##################################################################
#####RubyRetriever -- automated web crawler focused on finding
#####             	and downloading executables (namely, malware)
#####created by Joe Norton
#####http://softwarebyjoe.com
##LICENSING: GNU GPLv3  License##################################
#! usr/bin/ruby
require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'optparse'
require 'uri'
require 'csv'

require_relative('openuri_patch.rb')
require_relative('file_processor.rb')

module Retriever
		class Fetch
			attr_reader :target, :host
			#constants
			LINK_RE = Regexp.new(/[\b]*[http:\/\/]*[w]*[a-z0-9\-\_\.\!\/\%\=\&\?]+\b/ix).freeze
			def initialize(url,options)
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
				puts "###############################"
				puts "Data Dump: "
				puts "Object Count: #{data.size}"
				puts "###############################"
				puts data
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
				puts
			end
			def fetchDoc(url)
				return false if !url
				begin
					#grab site into Nokogiri object
					doc = Nokogiri::HTML(open(url,'User-Agent' => 'Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; Trident/6.0)'))
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
				#scrap all html links from site, easy peezy
				doc.xpath('//a/@href').each do |link|
					#filter some malformed URLS that come in
					link = link.to_s.strip.downcase
					if LINK_RE =~ link
						if (!(/^http/ =~ link))
							if (/^www\./ =~ link)
								link = "http://"+link
							elsif /^\/{1}[^\/]/ =~ link #link uses relative path
								if /\/\z/ =~ url #when url ends with slash we have to trim it when appending the new path	
									url = url[0..-2]
								end
								link = url+link #appending current url to relative paths
							else
								next
							end
						end
						next if /#[a-z0-9\_\-]*\z/ =~ link
						linkArray.push(link)
					end
				end
				linkArray.uniq!
				return linkArray
			end
		end
	class FetchFiles < Fetch
		attr_reader :fileStack
		def initialize(url,options)
			super	
			@fileStack = []
			@file_ext = options[:file_ext]
			tempExtStr = "."+@file_ext+'\z'
			@file_re = Regexp.new(tempExtStr).freeze
			@already_crawled = [@target]
			doc = fetchDoc(@target)
			all_links = fetchLinks(doc,@target)
			@linkStack = parseInternalLinks(all_links.dup,@host_re)
			lg("#{@linkStack.size-1} new links found") if @v
			tempFileCollection = parseFiles(all_links.dup,@file_re)
			@fileStack.concat(tempFileCollection) if tempFileCollection.size>0
			errlog("Bad URL -- #{@target}") if !@linkStack
			@linkStack.delete(@target) if @linkStack.include?(@target)
			@linkStack = @linkStack.take(@maxPages) if (@linkStack.size+1 > @maxPages)
			current_size = @already_crawled.size
			while (@linkStack.size > 0 && current_size < @maxPages)
				@linkStack.each do |url|
					#lg("looking at #{url}")
					break if (current_size+1 > @maxPages)
					doc = fetchDoc(url)
					next if !doc
					@already_crawled.push(url)
					lg("URL Crawled: #{url}") if @v
					lnks = fetchLinks(doc,url)
					filez = parseFiles(lnks.dup,@file_re)
					@fileStack.concat(filez) if !filez.empty?
					lg("#{filez.size} files found") if @v
					current_size += 1
					linkx = parseInternalLinks(lnks.dup,@host_re)
					next if linkx.empty?
					new_links_arr = linkx-@already_crawled #set operations to see are these in our previous visited pages arr?
					@linkStack.concat(new_links_arr) if !new_links_arr.empty?
					#lg("#{new_links_arr.size} new links found") if (!new_links_arr.empty? && @v)
				end
			end
			@fileStack.uniq!
			@fileStack.sort_by! {|x| x.length} if @fileStack.size>1
			self.dump(self.fileStack) if @v
			#self.write(@output,self.paths) if @output
		end
		def parseInternalLinks(all_links,host_re)
			all_links.select!{ |linky| (host_re =~ linky && (!(/\.(?:png|jpg|gif|mp4|exe|zip|pdf|ppt|doc|txt)\z/i =~ linky)))}
			#lg("#{all_links.size} unique internal links found")
		end
		def parseFiles(all_links,file_re)
			all_links.select!{ |linky| (file_re =~ linky)}
		end
	end
	class FetchSitemap < Fetch
		attr_reader :sitemap
		def initialize(url,options)
			super
			@sitemap = [@target]
			@linkStack = fetchInternalLinks(fetchDoc(@target),@target,@host_re)
			lg("#{@linkStack.size-1} new links found") if @v
			errlog("Bad URL -- #{@target}") if !@linkStack
			@linkStack.delete(@target) if @linkStack.include?(@target)
			@linkStack = @linkStack.take(@maxPages) if (@linkStack.size+1 > @maxPages)
			@sitemap.concat(@linkStack)
			while (@linkStack.size > 0 && @sitemap.size < @maxPages)
				current_size = @sitemap.size
				@linkStack.each do |url|
					#lg("looking at #{url}")
					break if (current_size+1 > @maxPages)
					doc = fetchDoc(url)
					next if !doc
					lg("URL Crawled: #{url}") if @v
					linkx = fetchInternalLinks(doc,url,@host_re)
					next if linkx.empty?
					new_links_arr = linkx - @sitemap #set operations to see are these in our previous visited pages arr?
					 if !new_links_arr.empty?
					 	@linkStack.concat(new_links_arr)
						@sitemap.concat(new_links_arr)
						lg("#{new_links_arr.size} new links found") if @v
						current_size += new_links_arr.size
					end
				end
			end
			@sitemap.sort_by! {|x| x.length}
			@sitemap = @sitemap.take(@maxPages) if (@sitemap.size+1 > @maxPages)
			self.dump(self.sitemap) if @v
			self.write(@output,self.sitemap) if @output
		end
		def fetchInternalLinks(doc,url,host_re)
			linkArray = self.fetchLinks(doc,url)
			return linkArray.select!{ |linky| (host_re =~ linky &&(!(/\.(?:png|jpg|gif|mp4|exe|zip|pdf|ppt|doc|txt)\z/i =~ linky)))} if !linkArray.empty?
		end
	end
end