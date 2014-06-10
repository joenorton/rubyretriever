module Retriever
  #
  class FetchSitemap < Fetch
    # recieves target URL and RR options
    # returns an array of all unique pages found on the site
    def initialize(url, options)
      super
      @data.concat(@t.target)
      @data.concat(@link_stack)

      async_crawl_and_collect

      @data.sort_by! { |x| x.length } if @data.size > 1
      @data.uniq!
    end

    # produces valid XML sitemap based on page collection fetched.
    # Writes to current directory.
    def gen_xml
      filename = @t.host.split('.')[1]
      f = File.open("sitemap-#{filename}.xml", 'w+')
      f << "<?xml version='1.0' encoding='UTF-8'?>"
      f << "<urlset xmlns='http://www.sitemaps.org/schemas/sitemap/0.9'>"
      @data.each do |url|
        f << "<url><loc>#{url}</loc></url>"
      end
      f << '</urlset>'
      f.close
      print_file_info(filename)
    end

    def print_file_info(filename)
      puts HR
      puts "File Created: sitemap-#{filename}.xml"
      puts "Object Count: #{@data.size}"
      puts HR + "\n"
    end
  end
end
