require_relative '../retriever'

r = Retriever::Fetch.new("http://www.cnet.com/reviews/",{})
test_html = "<a href='www.cnet.com/download.exe'>download</a>
http://www.google.com 
<a href='/test.html'>test</a>
<a href='http://www.cnet.com/products/gadgets#view-comments'>gadgets comments</a>
<a href='http://www.cnet.com/products/gadgets/' data-vanity-rewritten='true'></a>
<a href='http://www.cnet.com/products/gadgets/'>gadgets </a>
 <a href='http://www.yahoo.com/test/'>yahoo</a> 
 test.com
 <link rel='stylesheet' id='gforms_reset_css-css'  href='http://www.cnet.com/wp-content/plugins/gravityforms/css/formreset.css?ver=1.7.12' type='text/css' media='all' />"

doc = r.fetchDoc(r.target)
links_collection = r.fetchLinks(test_html,r.host)
filtered_links = r.parseInternalLinks(links_collection,r.host_re)

describe "Fetch" do
	describe "#new" do
		it "creates target & host vars from URL" do
			expect(r.target).to eq("http://www.cnet.com/reviews/")
			expect(r.host).to eq("www.cnet.com")
		end
	end

	describe "#fetchDoc" do
		it "opens URL and returns source as String" do
			expect(doc.class).to eq(String)
		end
	end

	describe "#fetchLinks" do
		it "collects all unique href links on the page" do
			expect(links_collection).to have(5).items
		end
		it "returns relative urls with full path based on hostname" do
			expect(links_collection[1]).to eq("http://www.cnet.com/test.html")
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

end