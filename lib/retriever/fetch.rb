require 'em-synchrony'
require 'em-synchrony/em-http'
require 'em-synchrony/fiber_iterator'
require 'ruby-progressbar'
require 'open-uri'
require 'csv'
require 'bloomfilter-rb'

module Retriever
  #
  class Fetch
    HR = '###############################'
    attr_reader :max_pages, :t
    # given target URL and RR options, creates a fetch object.
    # There is no direct output
    # this is a parent class that the other fetch classes build off of.
    def initialize(url, options)
      @data = []
      @connection_tally = {
        :success => 0,
        :error => 0,
        :error_client => 0,
        :error_server => 0
      }
      setup_options(options)
      setup_progress_bar if @progress

      @t = Retriever::Target.new(url, @file_re)
      @output = "rr-#{@t.host.split('.')[1]}" if @fileharvest && !@output

      @already_crawled = setup_bloom_filter

      @page_one = crawl_page_one
      @link_stack = create_link_stack
    end

    def errlog(msg)
      fail "ERROR: #{msg}"
    end

    def lg(msg)
      puts "### #{msg}" if @verbose
    end

    # prints current data collection to STDOUT
    def dump
      puts HR
      if @verbose
        puts 'Connection Tally:'
        puts @connection_tally.to_s
        puts HR
      end
        puts "Target URL: #{@t.target}"
      if @sitemap
        puts 'Sitemap'
      elsif @fileharvest
        puts "File harvest by type: #{@file_ext}"
      elsif @seo
        puts 'SEO Metrics'
      else
        fail 'ERROR - Cannot dump - Mode Not Found'
      end
      puts "Count: #{@data.size}"
      puts HR
      @data.each do |line|
        puts line
      end
      puts HR + "\n"
    end

    # writes current data collection out to CSV in current directory
    def write
      return false unless @output
      i = 0
      CSV.open("#{@output}.csv", 'w') do |csv|
        if (i == 0) && @seo
          csv << ['URL', 'Page Title', 'Meta Description', 'H1', 'H2']
          i += 1
        end
        @data.each do |entry|
          csv << entry
        end
      end
      puts HR
      puts "File Created: #{@output}.csv"
      puts "Object Count: #{@data.size}"
      puts HR
      puts
    end

    private

    def setup_options(options)
      @progress     = options['progress']
      @max_pages    = options['maxpages'] ? options['maxpages'].to_i : 100
      @verbose      = options['verbose']
      @output       = options['filename']
      @fileharvest  = options['fileharvest']
      @sitemap      = options['sitemap']
      @seo          = options['seo']
      @autodown     = options['autodown']
      #
      if @fileharvest
        temp_ext_str = '.' + @fileharvest + '\z'
        @file_re = Regexp.new(temp_ext_str).freeze
      else
        # when FH is not true, and autodown is true
        errlog('Cannot AUTODOWNLOAD when not in FILEHARVEST MODE') if @autodown
      end
    end

    def setup_bloom_filter
      already_crawled = BloomFilter::Native.new(
        :size => 1_000_000,
        :hashes => 5,
        :seed => 1,
        :bucket => 8,
        :raise => false
      )
      already_crawled.insert(@t.target)
      already_crawled
    end

    def setup_progress_bar
      # verbose & progressbar conflict
      errlog('CANNOT RUN VERBOSE & PROGRESSBAR AT SAME TIME, CHOOSE ONE, -v or -p') if @verbose
      prgress_vars = {
        :title => 'Pages',
        :starting_at => 1,
        :total => @max_pages,
        :format => '%a |%b>%i| %c/%C %t'
      }
      @progressbar = ProgressBar.create(prgress_vars)
    end

    def crawl_page_one
      page_one = Retriever::Page.new(@t.source, @t)
      lg("URL Crawled: #{@t.target}")
      page_one
    end

    def create_link_stack
      link_stack = @page_one.parse_internal_visitable
      errlog("Bad URL -- #{@t.target}") unless link_stack
      lg("#{link_stack.size - 1} links found")
      link_stack.delete(@t.target)
      link_stack.take(@max_pages) if (link_stack.size + 1) > @max_pages
      link_stack
    end

    def end_crawl_notice
      @progressbar.log("Can't find any more links.") if @prgress
      lg("Can't find any more links.")
    end

    # iterates over the existing @link_stack
    # running until we reach the @max_pages value.
    def async_crawl_and_collect
      while @already_crawled.size < @max_pages
        if @link_stack.empty?
          end_crawl_notice
          break
        end
        new_links_arr = process_link_stack
        next if new_links_arr.nil? || new_links_arr.empty?
        # set operations to see are these in our previous visited pages arr
        new_links_arr -= @link_stack
        next if new_links_arr.empty?
        @link_stack.concat(new_links_arr).uniq!
        next unless @sitemap
        @data.concat(new_links_arr)
      end
      # done, make sure progress bar says we are done
      @progressbar.finish if @progress
    end

    # returns true is resp is ok to continue
    def good_response?(resp, url)
      return false unless resp
      hdr = resp.response_header
      if hdr.redirection?
        loc = hdr.location
        lg("#{url} Redirected to #{loc}")
        if t.host_re =~ loc
          @link_stack.push(loc) unless @already_crawled.include?(loc)
          lg('--Added to linkStack for later')
          return false
        end
        lg("Redirection outside of target host. No - go. #{loc}")
        return false
      end
      # lets not continue if unsuccessful connection
      unless hdr.successful?
        lg("UNSUCCESSFUL CONNECTION -- #{url}")
        @connection_tally[:error] += 1
        @connection_tally[:error_server] += 1 if hdr.server_error?
        @connection_tally[:error_client] += 1 if hdr.client_error?
        return false
      end
      # let's not continue if not text/html
      unless hdr['CONTENT_TYPE'].include?('text/html')
        @already_crawled.insert(url)
        @link_stack.delete(url)
        lg("Page Not text/html -- #{url}")
        return false
      end
      @connection_tally[:success] += 1
      true
    end

    def push_seo_to_data(url, new_page)
      seos = [url]
      seos.concat(new_page.parse_seo)
      @data.push(seos)
      lg('--page SEO scraped')
    end

    def push_files_to_data(new_page)
      filez = new_page.parse_files(new_page.parse_internal)
      @data.concat(filez) unless filez.empty?
      lg("--#{filez.size} files found")
    end

    def page_from_response(url, response)
      lg("Page Fetched: #{url}")
      @already_crawled.insert(url)
      @progressbar.increment if @progress && (@already_crawled.size < @max_pages)
      Retriever::Page.new(response, @t)
    end

    # send a new wave of GET requests, using current @link_stack
    def process_link_stack
      new_stuff = []
      EM.synchrony do
        concurrency = 10
        EM::Synchrony::FiberIterator.new(@link_stack, concurrency).each do |url|
          next if @already_crawled.size >= @max_pages
          next if @already_crawled.include?(url)
          resp = EventMachine::HttpRequest.new(url).get
          next unless good_response?(resp, url)
          current_page = page_from_response(url, resp.response)
          # non-link dependent modes
          push_seo_to_data(url, current_page) if @seo
          next unless current_page.links.size > 0
          lg("--#{current_page.links.size} links found")
          new_stuff.push(current_page.parse_internal_visitable)
          # link dependent modes
          next unless @fileharvest
          push_files_to_data(current_page)
        end
        EventMachine.stop
      end
      new_stuff.flatten.uniq!
    end
  end
end
