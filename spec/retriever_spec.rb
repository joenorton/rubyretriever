require_relative '../retriever'

r = Retriever::Fetch.new("http://www.cnet.com",{})
test_html = "<a href='www.cnet.com/download.exe'>download</a>
http://www.google.com 
<a href='/test.html'>test</a>
<a href='http://www.cnet.com/products/gadgets#view-comments'>gadgets comments</a>
<a href='http://www.cnet.com/products/gadgets/' data-vanity-rewritten='true'></a>
<a href='http://www.cnet.com/products/gadgets/'>gadgets </a>
 <a href='http://www.yahoo.com/test/'>yahoo</a> 
 test.com"
doc = r.fetchDoc(r.target)
links_collection = r.fetchLinks(test_html,r.target)
filtered_links = r.parseInternalLinks(links_collection,r.host_re)

describe "Fetch" do

	describe "#new" do
		it "creates target & host vars from URL" do
			expect(r.target).to eq("http://www.cnet.com")
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
			expect(links_collection).to have(4).items
		end
	end

	describe "#parseInternalLinks" do
		it "filters links by host" do
			expect(filtered_links).to have(3).items
		end
	end

end