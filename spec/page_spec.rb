require 'retriever/page'

describe 'A Page' do
  describe '#links' do
    let(:page) do
      page = Retriever::Page.new("http://www.cnet.com/reviews/", false)
      page.stub(:source) { @source }

      page
    end

    let(:links) { page.links }

    it "collects links in anchor tags" do
      @source = (<<SOURCE).strip
<a href='http://www.cnet.com/download.exe'>download</a>
SOURCE

      expect(links).to include('http://www.cnet.com/download.exe')
    end

    it "collects links in link tags" do
      @source = (<<SOURCE).strip

 <link rel='stylesheet' id='gforms_reset_css-css'  href='http://www.cnet.com/wp-content/plugins/gravityforms/css/formreset.css?ver=1.7.12' type='text/css' media='all' />
SOURCE

      expect(links).to include('http://www.cnet.com/wp-content/plugins/gravityforms/css/formreset.css?ver=1.7.12')
    end

    it "does not collect bare links (ones not in an href)" do
      @source = (<<SOURCE).strip
http://www.google.com
SOURCE

      expect(links).to_not include('http://www.google.com')
    end

    it "collects only unique href links on the page" do
      @source = (<<SOURCE).strip
<a href='http://www.cnet.com/products/gadgets'>gadgets</a>
<a href='http://www.cnet.com/products/gadgets'>gadgets2</a>
SOURCE

      expect(links).to have(1).items
    end

    it "adds a protocol to urls missing them (www.)" do
      @source = (<<SOURCE).strip
<a href='www.cnet.com/download.exe'>download</a>
SOURCE

      expect(links).to include('http://www.cnet.com/download.exe')
    end

    it "doesn't care about any extra attributes on the anchor tag" do
      @source = (<<SOURCE).strip
<a href='http://www.cnet.com/products/gadgets/'>gadgets </a>
<a href='http://www.cnet.com/products/gadgets/' data-vanity-rewritten='true'></a>
SOURCE

      expect(links).to have(1).item
    end

    it "returns relative urls with full path based on hostname" do
      @source = (<<SOURCE).strip
<a href='/test.html'>test</a>
<a href='cpage_18'>about</a>
SOURCE

      expect(links).to include("http://www.cnet.com/test.html","http://www.cnet.com/cpage_18")
    end
  end
end
