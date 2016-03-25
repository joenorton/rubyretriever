module Retriever
  #
  class FetchSitemap < Fetch
    # receives target URL and RR options
    # returns an array of all unique pages found on the site
    def initialize(url, options)
      super
      start
      @result.push(@t.target)
      @result.concat(@link_stack)

      async_crawl_and_collect
      # done, make sure progress bar says we are done
      @progressbar.finish if @progress
      @result.sort_by! { |x| x.length } if @result.size > 1
      @result.uniq!
    end

    # produces valid XML sitemap based on page collection fetched.
    # Writes to current directory.
    def gen_xml
      filename = @t.host.split('.')[1]
      f = File.open("sitemap-#{filename}.xml", 'w+')
      f << "<?xml version='1.0' encoding='UTF-8'?>"
      f << "<urlset xmlns='http://www.sitemaps.org/schemas/sitemap/0.9'>"
      @result.each do |url|
        f << "<url><loc>#{url}</loc></url>"
      end
      f << '</urlset>'
      f.close
      print_file_info(filename)
    end

    private

    def print_file_info(filename)
      puts HR
      puts "File Created: sitemap-#{filename}.xml"
      puts "Object Count: #{@result.size}"
      puts HR + "\n"
    end
  end
end
