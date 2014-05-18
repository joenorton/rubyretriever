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
					doc = Nokogiri::HTML(open(url,'User-Agent' => 'RubyRetriever'))
					lg("URL Crawled: #{url}")
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
					link = link.to_s
					if /[\b]*[http:\/\/]*[w]*[a-z0-9\-\_\.\!\/\%\=\&\?]+\b/ix.match(link)
						linkArray.push(link)
					end
				end
				#if links do not contain domain, prepend the source domain name
				linkArray.each_with_index do |entry,i|
					if (!(/^http/.match(entry)))
						if (/^www\./.match(entry))
							linkArray[i] = "http://"+entry
						elsif (/^\//.match(entry))
							linkArray[i] = url+ entry #sourcedir_str + entry
						elsif /^\s/.match(entry)
							linkArray[i] = url+ entry.gsub(" ","%20")
						else
							linkArray.delete_at(i)
						end
					end
				end
				linkArray.uniq!
				return linkArray
			end
		end
	class FetchSitemap < Fetch
		attr_reader :sitemap
		def initialize(url,options)
			new_uri = URI(url)
			@target = new_uri.to_s
			@host = new_uri.host
			@sitemap = [@target]
			#opts
			if options.empty?
				@maxPages = 1000
				@v = false
				@output = false
			else
				@maxPages=options[:maxpages].to_i if options[:maxpages]
				@v=true if options[:verbose]
				@output=options[:filename] if options[:filename]
			end	
			@linkStack = fetchInternalLinks(fetchDoc(@target),@target,@host)
			errlog("Bad URL -- #{@target}") if !@linkStack
			@linkStack.delete(@target) if @linkStack.include?(@target)
			@linkStack = @linkStack.take(@maxPages) if (@linkStack.size+1 > @maxPages)
			@sitemap.concat(@linkStack)
			while (@linkStack.size > 0 && @sitemap.size < @maxPages)
				current_size = @sitemap.size
				@linkStack.each_with_index do |url,i|
					#lg("looking at #{url}")
					break if (current_size+1 > @maxPages)
					doc = fetchDoc(url)
					next if !doc
					linkx = fetchInternalLinks(doc,url,@host)
					next if !linkx
					linkx.each do |new_link|
						break if (current_size+1 > @maxPages)
						if @sitemap.include?(new_link)
							next
						end
						@linkStack.push(new_link)
						@sitemap.push(new_link)
						current_size += 1
					end
				end
			end
			@sitemap.sort_by! {|x| x.length}
			self.dump(self.sitemap) if @v
			self.write(@output,self.sitemap) if @output
		end
		def fetchInternalLinks(doc,url,host)
			linkArray = self.fetchLinks(doc,url)
			linkArray.select!{ |linky| (linky.include?(host)&&(!(/\.(?:png|jpg|gif|mp4|exe|zip|pdf|ppt|doc|txt)\b/.match(linky))))}
			lg("#{linkArray.size} unique internal links found")
			return linkArray
		end
	end
end