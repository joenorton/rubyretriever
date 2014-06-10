module Retriever
  # recieves target url and RR options
  # returns an array of all unique files (based on given filetype)
  #   found on the target site
  class FetchFiles < Fetch
    def initialize(url, options)
      super
      temp_file_collection = @page_one.parse_files
      @data.concat(tempFileCollection) if temp_file_collection.size > 0
      lg("#{@data.size} new files found")

      async_crawl_and_collect

      @data.sort_by! { |x| x.length }
      @data.uniq!
    end

    def download_file(path)
      # given valid url, downloads file to current directory in /rr-downloads/
      arr = path.split('/')
      shortname = arr.pop
      puts "Initiating Download of: #{shortname}"
      File.open(shortname, 'wb') do |saved_file|
        open(path) do |read_file|
          saved_file.write(read_file.read)
        end
      end
      puts '  SUCCESS: Download Complete'
    end

    def iterate_thru_collection_and_download
      file_counter = 0
      lenn = @data.count
      @data.each do |entry|
        begin
          download_file(entry)
        rescue StandardError
          puts 'ERROR: failed to download - #{entry}'
        end
        file_counter += 1
        lg("    File [#{file_counter} of #{lenn}]\n")
      end
    end

    def move_to_download_dir(dir_name = 'rr-downloads')
      if File.directory?(dir_name)
        Dir.chdir(dir_name)
      else
        puts 'creating #{dir_name} Directory'
        Dir.mkdir(dir_name)
        Dir.chdir(dir_name)
      end
      puts "Initiating Download to: '/#{dir_name}/'"
    end

    def autodownload
      # go through the fetched file URL collection and download each one.
      puts HR
      puts '### Initiating Autodownload...'
      puts HR
      puts "#{@data.count} - #{@file_ext}'s Located"
      puts HR
      move_to_download_dir
      iterate_thru_collection_and_download
      Dir.chdir('..')
    end
  end
end
