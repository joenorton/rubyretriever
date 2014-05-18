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
		def fetchInternalLinks(doc,url,root)
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
			#sort and remove dupes
			#if links do not contain domain, prepend the source domain name
			#sourcedir_str = get_source_dir(url)
			linkArray.each_with_index do |entry,i|
				if (!(/^http/.match(entry)))
					if (/^www\./.match(entry))
						linkArray[i] = "http://"+entry
					elsif (/^\//.match(entry))
						linkArray[i] = "http://" +root+ entry #sourcedir_str + entry
					elsif /^\s/.match(entry)
						linkArray[i] = "http://" +root+ entry.gsub(" ","%20")
					else
						linkArray.delete_at(i)
					end
				end
				if ((/\.(?:png|jpg|gif|mp4|exe|zip|pdf|ppt|doc|txt)\b/.match(entry)))
					linkArray.delete_at(i)
				end
			end
			linkArray.select!{ |linky| linky.include?(root)}
			linkArray.uniq!
			lg("#{linkArray.size} unique internal links found")
			return linkArray
		end
	class Sitemap
		include Retriever
		attr_reader :sitemap
		def initialize(url,options)
			new_uri = URI(url)
			@target = new_uri.to_s
			@root = new_uri.host
			@sitemap = [@target]
			#opts
			if !options.empty?
				@maxPages=options[:maxpages].to_i if options[:maxpages]
				@v=true if options[:verbose]
				@output=options[:filename] if options[:filename]
			else
				@maxPages = 1000
				@v = false
				@output = false
			end	
			@linkStack = fetchInternalLinks(fetchDoc(@target),@target,@root)
			errlog("Bad URL -- #{@target}") if !@linkStack
			@linkStack.delete(@target) if @linkStack.include?(@target)
			@linkStack = @linkStack.take(@maxPages) if (@linkStack.size+1 > @maxPages)
			@sitemap.concat(@linkStack)
			while (@linkStack.size > 0 && @sitemap.size < @maxPages)
				current_size = @sitemap.size
				@linkStack.each_with_index do |url,i|
					if current_size < @maxPages
						doc = fetchDoc(url)
						break if !doc
						linkx = fetchInternalLinks(doc,url,@root)
						break if !linkx
						linkx.each do |new_link|
							if current_size < @maxPages
								unique_link_flag = true
								if @sitemap.include?(new_link)
									unique_link_flag = false
								end
								if unique_link_flag
									@linkStack.push(new_link)
									@sitemap.push(new_link)
									current_size += 1
								end
							end
						end
					end
				end
			end
			@sitemap.sort_by! {|x| x.length}
			self.dump(self.sitemap) if @v
			self.write(@output,self.sitemap) if @output
		end
	end
end