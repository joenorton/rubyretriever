
require_relative('retriever.rb')
opts = []
test = Retriever::Sitemap.new(ARGV[0], opts)
test.dump(test.sitemap)
test.write(ARGV[1],test.sitemap)