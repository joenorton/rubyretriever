##################################################################
#####exe_processor.rb -- part of the RubyRetriever project
#####             
#####created by Joe Norton
#####http://softwarebyjoe.com
##LICENSING: GNU GPLv3  License###################################
def download_file(path)
	arr = path.split('/')
	shortname = arr.pop
	puts "Initiating Download to: #{'/samples/' + shortname}"
	File.open(shortname, "wb") do |saved_file|
	  # the following "open" is provided by open-uri
	  open(path) do |read_file|
	    saved_file.write(read_file.read)
	  end
	end
	puts "	SUCCESS: Download Complete"
end
def is_MZ?(path)
	already_crawled = nil
	for each in $dont_recrawl_file
		t = each.eql?path
		if t
			already_crawled = t
		end
	end
	if !already_crawled
		begin
			query = open(path, "rb")
			#here we grab the first 2 bytes of the file to see if it is a MZ
			chunk = ""
			2.times do 
				chunk << query.getbyte
			end
			chunk = chunk.to_s
			#	chunk = IO.binread(query,2,0).to_s
			query.close
			if (chunk == "MZ")
				return path
			else
				return false
			end
		rescue StandardError => e
			puts e.message
			return false
		end
	else
		puts "#{filetypeX.upcase} Already crawled"
		return false
	end
end
def is_pdf?(path)
	already_crawled = nil
	for each in $dont_recrawl_file
		t = each.eql?path
		if t
			already_crawled = t
		end
	end
	if !already_crawled
		begin
			query = open(path, "rb")
			#here we grab the first 2 bytes of the file to see if it is a MZ
			chunk = ""
			4.times do 
				chunk << query.getbyte
			end
			chunk = chunk.to_s
			#	chunk = IO.binread(query,2,0).to_s
			query.close
			if (chunk == "%PDF")
				return path
			else
				return false
			end
		rescue StandardError => e
			puts e.message
			return false
		end
	else
		puts "PDF Already crawled"
		return false
	end
end
#mz_check recieves array of potential EXE's
#it checks then one by one for MZ's
#it also does the logging for the processing
def filetype_check(arrayX,filetypeX)
	puts 
	puts "##### Now Verifying Potential File's #####"
	count = arrayX.count
	verifiedArray = []
	if count > 0
		arrayX.each_with_index do |each,i|
			if (/\.(?:html|js)\/[\w\-]+\.#{filetypeX}/ix.match(each))
				puts "[#{i+1} of #{count}] - Malformed URL #{each}"
			else
				if filetypeX == "exe"
					if is_MZ?(each)
						puts "[#{i+1} of #{count}] - EXE VERIFIED### #{each}"
						verifiedArray << each
					else
						puts "[#{i+1} of #{count}] - No MZ #{each}"
					end
				elsif filetypeX == "pdf"
					if is_pdf?(each)
						puts "[#{i+1} of #{count}] - PDF VERIFIED### #{each}"
						verifiedArray << each
					else
						puts "[#{i+1} of #{count}] - No PDF #{each}"
					end
				else
					puts "No specific test for this filetype, verifying all"
					verifiedArray << each
				end
			end
		end
	end
	return verifiedArray
end

def to_hex_string(byteform)
    return byteform.unpack('H*')
end
