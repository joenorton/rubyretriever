module Retriever
	class FetchFiles < Fetch
		def initialize(url,options)
			super
			@data = []
			page_one = Retriever::Page.new(@t.source,@t)
			@linkStack = page_one.parseInternalVisitable
			lg("URL Crawled: #{@t.target}")
			lg("#{@linkStack.size-1} new links found")

			tempFileCollection = page_one.parseFiles
			@data.concat(tempFileCollection) if tempFileCollection.size>0
			lg("#{@data.size} new files found")
			errlog("Bad URL -- #{@t.target}") if !@linkStack

			@linkStack.delete(@t.target) if @linkStack.include?(@t.target)
			@linkStack = @linkStack.take(@maxPages) if (@linkStack.size+1 > @maxPages)

			self.async_crawl_and_collect()

			@data.sort_by! {|x| x.length}
			@data.uniq!
		end
		def download_file(path)
			arr = path.split('/')
			shortname = arr.pop
			puts "Initiating Download to: #{'/rr-downloads/' + shortname}"
			File.open(shortname, "wb") do |saved_file|
			  # the following "open" is provided by open-uri
			  open(path) do |read_file|
			    saved_file.write(read_file.read)
			  end
			end
			puts "	SUCCESS: Download Complete"
		end
		def autodownload()
			lenny = @data.count
			puts "###################"
			puts "### Initiating Autodownload..."
			puts "###################"
			puts "#{lenny} - #{@file_ext}'s Located"
			puts "###################"
			if File::directory?("rr-downloads")
			 Dir.chdir("rr-downloads")
			else
			puts "creating rr-downloads Directory"
			 Dir.mkdir("rr-downloads")
			 Dir.chdir("rr-downloads")
			end
			file_counter = 0
			@data.each do |entry|
				begin	
					self.download_file(entry)
					file_counter+=1
					lg("		File [#{file_counter} of #{lenny}]")
					puts
				rescue StandardError => e
					puts "ERROR: failed to download - #{entry}"
					puts e.message
					puts
				end
			end
			Dir.chdir("..")
		end
	end
end