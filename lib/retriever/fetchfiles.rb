module Retriever
	class FetchFiles < Fetch
		attr_reader :fileStack
		def initialize(url,options)
			super
			@fileStack = []
			all_links = self.fetchLinks(fetchPage(@target))
			@linkStack = self.parseInternalLinks(all_links)
			self.lg("#{@linkStack.size-1} new links found")

			tempFileCollection = self.parseFiles(all_links)
			@fileStack.concat(tempFileCollection) if tempFileCollection.size>0
			self.lg("#{@fileStack.size} new files found")
			errlog("Bad URL -- #{@target}") if !@linkStack

			@linkStack.delete(@target) if @linkStack.include?(@target)
			@linkStack = @linkStack.take(@maxPages) if (@linkStack.size+1 > @maxPages)

			self.async_crawl_and_collect()

			@fileStack.sort_by! {|x| x.length}
			@fileStack.uniq!

			self.dump(self.fileStack)
			self.write(@output,self.fileStack) if @output
			self.autodownload()
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
			lenny = @fileStack.count
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
			@fileStack.each do |entry|
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