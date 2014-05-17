##################################################################
#####crawl_url.rb -- part of the RubyRetriever project
#####             
#####created by Joe Norton
#####http://softwarebyjoe.com
##LICENSING: GNU GPLv3  License###################################
def process_links_for_filetype_only(site_links, filetypeX)
	#recieves array of site links
	#checks them all for exe's only
	#returns array of exe's
	dive_filetype_list = []
	site_links.each_with_index do |webpage,i|
		tempCrawlArray = filetype_only_crawl(webpage,filetypeX)
		if tempCrawlArray
			if (tempCrawlArray.count > 0)
				puts "[#{i+1} of #{site_links.count}] ### #{filetypeX}  Located on: #{webpage}"
				for filetype_url in tempCrawlArray
					puts "##### " + filetype_url
					dive_filetype_list.push(filetype_url)
				end
				puts
			else
				puts "[#{i+1} of #{site_links.count}] - No #{filetypeX} Located on #{webpage}"
				puts
			end
		end
	end
	return dive_filetype_list
end
def name_and_count_array(crawlerArray,filetypeX)
	puts "#{crawlerArray[0].count} - #{filetypeX.upcase} links"
	puts "#{crawlerArray[1].count} - html links"
	puts "#{crawlerArray[2].count} - jslinks"
	puts
end
def filter_for_endings(arr,filetypeX)
	endings_regex = ['#{filetypeX}','html','htm','php','js','asp','apsx']
	arr.each_with_index do |chunk,q|
		endings_regex.each do |endingStr|
			regex = /\.#{endingStr}/i
			if (regex.match(chunk))
				arr.delete_at(q)
			end
		end
	end
	return arr
end
def get_source_dir(query,filetypeX)
	querycopy = query.dup
	querycopy.slice! "http://"
	querycopy.gsub!('//','/')
	arr = querycopy.split('/')
	filtered_once = filter_for_endings(arr,filetypeX)
	filtered_twice = filter_for_endings(filtered_once,filetypeX)
	new_query = filtered_twice.join('/')
	new_query = 'http://' + new_query
	return new_query
end
def gather_filetype(site_str,sourcedir_str,filetypeX)
		#recieves a string of program source, and string of query without slashes
		#grab any full URLS ending in .exe
		#returns array of executables
		file_list = site_str.scan(/[\b]*[http:\/\/]*[w]*[a-z0-9\-\_\.\!\/\%\=\\&\?]+\.#{filetypeX}(?=\W)/ix)
		jicFileList = site_str.scan(/http:\/\/[^\s<>\[\]\(\)]+\.#{filetypeX}(?=\W)/ix)
		file_list += jicFileList
		file_list.each_with_index do |path,i|
			if (!(/^(http|https):\/\//.match(path)))
				if (/^\/\//.match(path))
					#path contains 2 slashes, we remove one and then prepend http://
					file_listt[i] = 'http:' + path.to_s
				elsif (/^\//.match(path))
					#prepend full query URL to path
					file_list[i] = sourcedir_str + path.to_s
				elsif (/^:\/\//.match(path))
					#go right to the http
					file_list[i] = 'http' + path.to_s
				else
					#we found a rogue .exe, so lets prepend the rootdomain of the query to see if that exists
					file_list[i] = sourcedir_str + "/" + path.to_s
				end
			end
		end
		file_list.sort!
		file_list.uniq!
		return file_list
end
def gather_js(doc,jsText,sourcedir_str)
	#recieves nokogiri doc object, and string of site JS
	#returns array of JS links
	jsArray = jsText.scan(/[\b]*[http:\/\/]*[w]*[a-z0-9\-\_\.\!\/\%\=\\&\?]+\.js(?=\W)/ix)
	jicJSArray= jsText.scan(/http:\/\/[^\s<>\[\]\(\)]+\.js(?=\W)/ix)
	jsArray += jicJSArray
	jsArray.each_with_index do |jslink,i|
		if jslink.eql?"google-analytics.com/ga.js"
			jsArray.delete_at(i)
		end
	end
	scriptSource = doc.xpath('//script/@src').to_a
	scriptSource.each_with_index do |entry,i|
		scriptSource[i] = entry.to_s
	end
	jsArray += scriptSource
	jsArray.each_with_index do |link,i|
		if (/^\./.match(link))
			len = link.length
			jsArray[i] = link[1..len]
		end
		if (!(/^(http|https):\/\//.match(link)))
			if (/^\/\//.match(link))
				#path contains 2 slashes, we remove one and then prepend http://
				jsArray[i] = 'http:' + link.to_s
			elsif (/^\//.match(link))
				#prepend full query URL to path
				jsArray[i] = sourcedir_str + link.to_s
			#else
				#we found a rogue .js, so lets prepend the rootdomain of the query to see if that exists
			#	jsArray[i] = sourcedir_str + "/" + link.to_s
			end
		end
	end
	jsArray.sort!
	jsArray.uniq!
	return jsArray
end
def gather_links(doc,query,filetypeX)
	#recieves nokogiri doc object, and string query
	#returns array of links
	linkArray = []
	#scrap all html links from site, easy peezy
	doc.xpath('//a/@href').each do |link|
		#filter some malformed URLS that come in
		link = link.to_s
		if /\s/.match(link)
			link = link.gsub(" ","%20")
		end
		if /[\b]*[http:\/\/]*[w]*[a-z0-9\-\_\.\!\/\%\=\&\?]+\b/ix.match(link)
			linkArray.push(link)
		end
	end
	#sort and remove dupes
	linkArray.sort!
	linkArray.uniq!
	#if links do not contain domain, prepend the source domain name
	sourcedir_str = get_source_dir(query,filetypeX)
	linkArray.each_with_index do |entry,i|
		if (!(/^http/.match(entry)))
			if (/^\//.match(entry))
				lenny = entry.length
				linkArray[i] = sourcedir_str + entry

			#else
			#	linkArray[i] = sourcedir_str  + '/' + entry
			end
		end
	end
	return linkArray
end
def filetype_only_crawl(query,filetypeX)
	already_crawled = nil
	for each in $dont_recrawl
		t = each.eql?query
		if t
			already_crawled = t
		end
	end
	if !already_crawled
		begin
			#grab site into Nokogiri object
			doc = Nokogiri::HTML(open(query,'User-Agent' => 'ruby'))
		rescue StandardError => e
			puts e.message + " ## " + query
			puts
			#the trap abrt is nescessary to handle the SSL error
			#for some ungodly reason it's the only way I found to handle it
			$dont_recrawl << query
			trap("ABRT"){
				puts "#{query} failed SSL Certification Verification"
				puts
			}
			return false
		end
		sourcedir_str = get_source_dir(query,filetypeX)
		#make string version of page source code
		site_str = doc.to_s
		jsText = (doc.xpath('//script').text)
		jsText.gsub!(/[^\x00-\x7F]/n,'?')
		site_str += " " + jsText
		#gather all elements
		file_list = gather_filetype(site_str,sourcedir_str,filetypeX)
		#add query to the 'do not recrawl' list
		$dont_recrawl << query
		#return an array, cell 1 ==> all exes on page, cell 2 ==> all normal URLS on page, cell 3 ==> all js links on page
		return file_list
	else
		puts "Already Crawled: #{query}"
		puts
		return false
	end
end
def deep_crawl_url(query,filetypeX)
	already_crawled = nil
	for each in $dont_recrawl
		t = each.eql?query
		if t
			already_crawled = t
		end
	end
	if !already_crawled
		begin
			#grab site into Nokogiri object
			doc = Nokogiri::HTML(open(query,'User-Agent' => 'ruby'))
		rescue StandardError => e
			puts e.message + " ## " + query
			#the trap abrt is nescessary to handle the SSL error
			#for some ungodly reason it's the only way I found to handle it
			$dont_recrawl << query
			trap("ABRT"){
				puts "#{query} failed SSL Certification Verification"
			}
			return false
		end
		sourcedir_str = get_source_dir(query,filetypeX)
		#make string version of page source code
		site_str = doc.to_s
		jsText = (doc.xpath('//script').text)
		site_str += " " + jsText
		#gather all elements
		file_list = gather_filetype(site_str,sourcedir_str,filetypeX)
		jsArray = gather_js(doc,jsText,sourcedir_str)
		linkArray = gather_links(doc,query,filetypeX)
		#put elements into array for returning later
		finalArr = [file_list,linkArray,jsArray]
		#add query to the 'do not recrawl' list
		$dont_recrawl << query
		#return an array, cell 1 ==> all exes on page, cell 2 ==> all normal URLS on page, cell 3 ==> all js links on page
		return finalArr
	else
		puts "Already Crawled: #{query}"
		return false
	end
end
def download_files_and_end(filetypeX)
	$final_list_of_filetype.uniq!
		$final_list_of_filetype.sort!
		unique_file_list = []
		$final_list_of_filetype.each_with_index do |path,i|
				arr = path.split('/')
				shortname = arr.pop
				bool = false
				for each in unique_file_list
					if each.eql?shortname
						bool = true
					end
				end
				if bool
					$final_list_of_filetype.delete_at(i)
				end
				unique_file_list.push(shortname)
		end
		#$final_list_of_filetype = filetype_check($final_list_of_filetype,filetypeX)
		if $final_list_of_filetype.count > 0
			puts
			puts "#{$final_list_of_filetype.count} - #{filetypeX}s Located"
			puts "###################"
			if File::directory?("samples")
			 Dir.chdir("samples")
			else
			puts "creating Samples Directory"
			 Dir.mkdir("samples")
			 Dir.chdir("samples")
			end
			lenny = $final_list_of_filetype.count
			file_counter = 0
			$final_list_of_filetype.each do |entry|
				begin	
					download_file(entry)
					file_counter+=1
					puts "		File [#{file_counter} of #{lenny}]"
					puts
				rescue StandardError => e
					puts "ERROR: failed to download - #{entry}#"
					puts e.message
					puts
				end
			end
			Dir.chdir("..")
			puts
			puts "### Crawl Complete ###"
			puts
		else
			puts
			puts "No Files Located"
			puts "###################"
			puts
		end
end
def crawl_main(initial_query,options)
	filetypeX = options[:filetype]
	quick_flag = options[:quick]
	if (!quick_flag)
		puts "### Starting Crawl ###"
		crawlerArray = deep_crawl_url(initial_query,filetypeX)
		if crawlerArray[0].count > 0
			$final_list_of_filetype += crawlerArray[0]
		end
		puts 
		puts "### Primary Query: #{initial_query}"
		name_and_count_array(crawlerArray,filetypeX)
		site_links = crawlerArray[1] + crawlerArray[2]
		if site_links.count > 0
			site_links.each do |link|
				results = deep_crawl_url(link,filetypeX)
				if results
					if results[0].count > 0
						$final_list_of_filetype += results[0]
					end
				end
			end
		end
		download_files_and_end(filetypeX)
	elsif quick_flag
			puts "### Starting Crawl ###"
			crawlerArray = filetype_only_crawl(initial_query,filetypeX)
			if (crawlerArray.count > 0)
				$final_list_of_filetype += crawlerArray
			end
			download_files_and_end(filetypeX)
	end
end