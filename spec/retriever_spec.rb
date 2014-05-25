require_relative '../lib/retriever'

r = Retriever::Fetch.new("http://www.cnet.com/reviews/",{:file_ext => "exe",:maxpages => "100"})
test_html = "<a href='www.cnet.com/download.exe'>download</a>
http://www.google.com 
<a href='/test.html'>test</a>
<a href='http://www.cnet.com/products/gadgets#view-comments'>gadgets comments</a>
<a href='http://www.cnet.com/products/gadgets/' data-vanity-rewritten='true'></a>
<a href='http://www.cnet.com/products/gadgets/'>gadgets </a>
 <a href='http://www.yahoo.com/test/'>yahoo</a> 
 test.com
 <link rel='stylesheet' id='gforms_reset_css-css'  href='http://www.cnet.com/wp-content/plugins/gravityforms/css/formreset.css?ver=1.7.12' type='text/css' media='all' />
 <a href='cpage_18'>about</a>"

doc = r.fetchPage(r.target)
links_collection = r.fetchLinks(test_html)
filtered_links = r.parseInternalLinks(links_collection)
file_list = r.parseFiles(links_collection)

describe "Fetch" do

	describe "#new" do
		it "sets target, host, and max page vars" do
			expect(r.target).to eq("http://www.cnet.com/reviews/")
			expect(r.host).to eq("www.cnet.com")
			expect(r.maxPages).to eq(100)
		end
	end

	describe "#fetchPage" do
		it "opens URL and returns source as String" do
			expect(doc.class).to eq(String)
		end
	end

	describe "#fetchLinks" do
		it "collects all unique href links on the page" do
			expect(links_collection).to have(6).items
		end
		it "returns relative urls with full path based on hostname" do
			expect(links_collection).to include("http://www.cnet.com/test.html","http://www.cnet.com/cpage_18")
		end
	end

	describe "#parseInternalLinks" do
		it "filters links by host" do
			filtered_links.each do |link| 
				expect(link).to include(r.host)
			end
		end
		it "filters out 'unvisitable' URLS like JS, Stylesheets, Images" do
			filtered_links.each do |link| 
				expect(link).to_not (include(".css",".js",".png",".gif",".jpg"))
			end
		end
	end
	describe "#parseFiles" do
		it "filters links by filetype" do
			file_list.each do |link|
				expect(link).to include(".exe")
			end
		end
	end

end