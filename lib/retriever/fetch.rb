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
    attr_reader :max_pages, :t, :result
    # given target URL and RR options, creates a fetch object.
    # There is no direct output
    # this is a parent class that the other fetch classes build off of.
    def initialize(url, options)
      @iterator = false
      @result = []
      @connection_tally = {
        success: 0,
        error: 0,
        error_client: 0,
        error_server: 0
      }
      setup_options(options)
      setup_progress_bar if @progress
      @t = Retriever::Target.new(url, @file_re)
      @output = "rr-#{@t.host.split('.')[1]}" if @fileharvest && !@output
      @already_crawled = setup_bloom_filter
    end

    def start
      @page_one = crawl_page_one
      @link_stack = create_link_stack
      @temp_link_stack = []
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
      puts "Connection Tally:\n#{@connection_tally}\n#{HR}" if @verbose
      puts "Target URL: #{@t.target}"
      if @sitemap
        puts 'Sitemap'
      elsif @fileharvest
        puts "File harvest by type: #{@fileharvest}"
      elsif @seo
        puts 'SEO Metrics'
      end
      puts "Data Dump -- Object Count: #{@result.size}"
      puts HR
      @result.each do |line|
        puts line
      end
      puts
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
        @result.each do |entry|
          csv << entry
        end
      end
      puts HR
      puts "File Created: #{@output}.csv"
      puts "Object Count: #{@result.size}"
      puts HR
      puts
    end

 # returns true is resp is ok to continue
    def good_response?(resp, url)
      return false unless resp
      hdr = resp.response_header
      if hdr.redirection?
        loc = hdr.location
        lg("#{url} Redirected to #{loc}")
        if t.host_re =~ loc
          @temp_link_stack.push(loc) unless @already_crawled.include?(loc)
          lg('--Added to stack for later')
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
      unless hdr['CONTENT_TYPE'] =~ %r{(text/html|application/xhtml+xml)}
        @already_crawled.insert(url)
        lg("Page Not text/html -- #{url}")
        return false
      end
      @connection_tally[:success] += 1
      true
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
      @file_re      = Regexp.new(/.#{@fileharvest}\z/).freeze if @fileharvest
    end

    def setup_bloom_filter
      already_crawled = BloomFilter::Native.new(
        size: 1_000_000,
        hashes: 5,
        seed: 1,
        bucket: 8,
        raise: false
      )
      already_crawled.insert(@t.target)
      already_crawled
    end

    def setup_progress_bar
      # verbose & progressbar conflict
      errlog('CANNOT RUN VERBOSE & PROGRESSBAR AT SAME TIME') if @verbose
      prgress_vars = {
        title: 'Pages',
        starting_at: 1,
        total: @max_pages,
        format: '%a |%b>%i| %c/%C %t'
      }
      @progressbar = ProgressBar.create(prgress_vars)
    end

    def crawl_page_one
      page_one = Retriever::Page.new(@t.target, @t.source, @t)
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
      notice = "#{HR}\nENDING CRAWL\nCan't find any more links."
      @progressbar.log(notice) if @progress
      lg(notice)
    end

    # iterates over the existing @link_stack
    # running until we reach the @max_pages value.
    def async_crawl_and_collect(&block)
      while @already_crawled.size < @max_pages
        if @link_stack.empty?
          end_crawl_notice
          break
        end
        new_links_arr = process_link_stack(&block)
        @temp_link_stack = []
        next if new_links_arr.nil? || new_links_arr.empty?
        @link_stack.concat(new_links_arr)
        next unless @sitemap
        @result.concat(new_links_arr)
      end
      @result.uniq!
    end

    def push_seo_to_result(url, new_page)
      seos = [url]
      seos.concat(new_page.parse_seo)
      @result.push(seos)
      lg('--page SEO scraped')
    end

    def push_files_to_result(new_page)
      filez = new_page.parse_files(new_page.parse_internal)
      @result.concat(filez) unless filez.empty?
      lg("--#{filez.size} files found")
    end

    def page_from_response(url, response)
      lg("Page Fetched: #{url}")
      @already_crawled.insert(url)
      if @progress && (@already_crawled.size < @max_pages)
        @progressbar.increment
      end
      Retriever::Page.new(url, response, @t)
    end

    def new_visitable_links(current_page)
      lg("--#{current_page.links.size} links found")
      current_page.parse_internal_visitable
    end

    def push_custom_to_result(url, current_page, &block)
      data = block.call current_page
      @result.push(data) unless data.empty?
      lg("-- PageIterator called on: #{url}")
    end

    # send a new wave of GET requests, using current @link_stack
    # at end of the loop it empties link_stack
    # puts new links into temporary stack
    def process_link_stack(&block)
      EM.synchrony do
        concurrency = 10
        EM::Synchrony::FiberIterator.new(@link_stack, concurrency).each do |url|
          next if @already_crawled.size >= @max_pages
          next if @already_crawled.include?(url)
          resp = EventMachine::HttpRequest.new(url).get
          next unless good_response?(resp, url)
          current_page = page_from_response(url, resp.response)
          # non-link dependent modes
          push_seo_to_result(url, current_page) if @seo
          push_custom_to_result(url, current_page, &block) if @iterator
          next unless current_page.links.size > 0
          @temp_link_stack.push(new_visitable_links(current_page))
          # link dependent modes
          next unless @fileharvest
          push_files_to_result(current_page)
        end
        EventMachine.stop
      end
      # empty the stack. most clean way
      @link_stack = []
      # temp contains redirects + new visitable links
      @temp_link_stack.flatten.uniq!
    end
  end
end
