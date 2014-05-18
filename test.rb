
require_relative('retriever.rb')
options = {}
 optparse = OptionParser.new do|opts|
   # Set a banner, displayed at the top
   # of the help screen.
   opts.banner = "Usage: retriever.rb [options] Target_URL"
 
    options[:filename] = nil
   opts.on( '-o', '--out FILENAME', 'Dump output to selected filename' ) do|filename|
     options[:filename] = filename
   end
   # Define the options, and what they do
   options[:verbose] = false
   opts.on( '-v', '--verbose', 'Output more information' ) do
     options[:verbose] = true
   end
 
    options[:maxpages] = false
   opts.on( '-l', '--limit PAGE_LIMIT_#', 'set a max on the total number of crawled pages' ) do |maxpages|
     options[:maxpages] = maxpages
   end
 
   # This displays the help screen, all programs are
   # assumed to have this option.
   opts.on( '-h', '--help', 'Display this screen' ) do
     puts opts
     exit
   end
 end
 
 optparse.parse!
 if ARGV[0].nil?
 	abort("###Missing Required Argument\nUsage: retriever.rb [options] Target_URL")
 end

puts "Writting output to filename: #{options[:filename]}" if options[:filename]
puts "Being verbose" if options[:verbose]
puts "Stopping after #{options[:maxpages]} pages" if options[:maxpages]
 
puts "Performing task with options: #{options.inspect}"
ARGV.each do|q|
   puts "######Initiating Crawl on #{q}..."
   test = Retriever::FetchSitemap.new(q, options)
   puts "######End of Crawl"
 end