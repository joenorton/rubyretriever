module Retriever
  # receives target url and RR options
  # returns an array of all unique files (based on given filetype)
  #   found on the target site

  class FetchFiles < Fetch
    def initialize(url, options)
      super
      start
      temp_file_collection = @page_one.parse_files(@page_one.parse_internal)
      @result.concat(temp_file_collection) if temp_file_collection.size > 0
      lg("#{@result.size} new files found")

      async_crawl_and_collect
      # done, make sure progress bar says we are done
      @progressbar.finish if @progress
      @result.sort_by! { |x| x.length }
    end

    def download_file(path)
      path = filter_out_querystrings(path)
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

    def autodownload
      # go through the fetched file URL collection and download each one.
      puts HR
      puts '### Initiating Autodownload...'
      puts HR
      puts "#{@result.count} - #{@file_ext}'s Located"
      puts HR
      move_to_download_dir
      iterate_thru_collection_and_download
      Dir.chdir('..')
    end

    private

    def iterate_thru_collection_and_download
      lenn = @result.count
      @result.each_with_index do |entry, i|
        begin
          download_file(entry)
        rescue StandardError
          puts "ERROR: failed to download - #{entry}"
        end
        lg("    File [#{i + 1} of #{lenn}]\n")
      end
    end

    def move_to_download_dir(dir_name = 'rr-downloads')
      if File.directory?(dir_name)
        Dir.chdir(dir_name)
      else
        puts "creating #{dir_name} Directory"
        Dir.mkdir(dir_name)
        Dir.chdir(dir_name)
      end
      puts "Downloading files to local directory: '/#{dir_name}/'"
    end
  end
end