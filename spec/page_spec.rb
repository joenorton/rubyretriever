require 'retriever/page'
require 'retriever/fetch'

t = Retriever::Target.new("http://www.cnet.com/reviews/",/\.exe\z/)

describe "Page" do

  describe "#links" do
    let (:links){Retriever::Page.new(@source,t).links}
    it "collects all unique href links on the page" do
            @source = (<<SOURCE).strip
<a href='www.cnet.com/download.exe'>download</a>
<a href='/test.html'>test</a>
<a href='http://www.cnet.com/products/gadgets/' data-vanity-rewritten='true'></a>
<a href='http://www.cnet.com/products/gadgets/'>gadgets </a>
 <a href='http://www.yahoo.com/test/'>yahoo</a> 
SOURCE

      expect(links).to have(4).items
    end
  end

  describe "#parseInternal" do
    let (:links){Retriever::Page.new(@source,t).parseInternal}
    it "filters links by host" do
            @source = (<<SOURCE).strip
<a href='http://www.cnet.com/'>download</a>
 <a href='http://www.yahoo.com/test/'>yahoo</a> 
SOURCE

        expect(links).to have(1).items
    end
  end

  describe "#parseInternalVisitable" do
    let (:links){Retriever::Page.new(@source,t).parseInternalVisitable}
    it "filters out 'unvisitable' URLS like JS, Stylesheets, Images" do
            @source = (<<SOURCE).strip
 <link rel='stylesheet' id='gforms_reset_css-css'  href='http://www.cnet.com/wp-content/plugins/gravityforms/css/formreset.css?ver=1.7.12' type='text/css' media='all' />
SOURCE
        expect(links).to have(0).items
    end
  end

  describe "#parseFiles" do
    let (:links){Retriever::Page.new(@source,t).parseFiles}
    it "filters links by filetype" do
                  @source = (<<SOURCE).strip
<a href='www.cnet.com/download.exe'>download</a>
http://www.google.com 
<a href='/test.html'>test</a>
SOURCE
        expect(links).to have(1).items
    end
  end

end