module Retriever
  # recieves target url and RR options
  # returns an array of all unique files (based on given filetype)
  #   found on the target site
  class FetchFiles < Fetch
    def initialize(url, options)
      super
      @data = []
      page_one = Retriever::Page.new(@t.source, @t)
      @link_stack = page_one.parse_internal_visitable
      lg("URL Crawled: #{@t.target}")
      lg("#{@link_stack.size - 1} new links found")

      temp_file_collection = page_one.parse_files
      @data.concat(tempFileCollection) if temp_file_collection.size > 0
      lg("#{@data.size} new files found")
      errlog("Bad URL -- #{@t.target}") unless @link_stack
      @link_stack.delete(@t.target)

      async_crawl_and_collect

      @data.sort_by! { |x| x.length }
      @data.uniq!
    end

    def download_file(path)
      # given valid url, downloads file to current directory in /rr-downloads/
      arr = path.split('/')
      shortname = arr.pop
      puts "Initiating Download to: '/rr-downloads/' + #{shortname}"
      File.open(shortname, 'wb') do |saved_file|
        open(path) do |read_file|
          saved_file.write(read_file.read)
        end
      end
      puts '  SUCCESS: Download Complete'
    end

    def autodownload
      # go through the fetched file URL collection and download each one.
      lenny = @data.count
      puts '###################'
      puts '### Initiating Autodownload...'
      puts '###################'
      puts "#{lenny} - #{@file_ext}'s Located"
      puts '###################'
      if File.directory?('rr-downloads')
        Dir.chdir('rr-downloads')
      else
        puts 'creating rr-downloads Directory'
        Dir.mkdir('rr-downloads')
        Dir.chdir('rr-downloads')
      end
      file_counter = 0
      @data.each do |entry|
        begin
          download_file(entry)
          file_counter += 1
          lg('    File [#{file_counter} of #{lenny}]')
          puts
        rescue StandardError => e
          puts 'ERROR: failed to download - #{entry}'
          puts e.message
          puts
        end
      end
      Dir.chdir('..')
    end
  end
end
