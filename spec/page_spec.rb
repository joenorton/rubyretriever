require 'retriever/page'
require 'retriever/fetch'

t = Retriever::Target.new('http://www.cnet.com/reviews/', /\.exe\z/)

describe 'Page' do
  describe '#url' do
    let(:page) { Retriever::Page.new('http://www.cnet.com/', @source, t) }
    it 'returns current page URL' do
      @source = (<<SOURCE).strip
<a href='http://www.cnet.com/'>download</a>
SOURCE
      expect(page.url).to eq('http://www.cnet.com/')
    end
  end

  describe '#links' do
    let(:page) { Retriever::Page.new('http://www.cnet.com/', @source, t) }
    it 'collects all unique href links on the page' do
      @source = (<<SOURCE).strip
<a href='www.cnet.com/download.exe'>download</a>
<a href='/test.html'>test</a>
<a href='http://www.cnet.com/products/gadgets/' data-vanity-rewritten='true'>
</a>
<a href='http://www.cnet.com/products/gadgets/'>gadgets </a>
 <a href='http://www.yahoo.com/test/'>yahoo</a>
SOURCE

      expect(page.links.size).to eq(4)
    end
  end

  describe '#parse_internal' do
    let(:page) { Retriever::Page.new('http://www.cnet.com/', @source, t) }
    let(:links) { page.parse_internal }
    it 'filters links by host' do
      @source = (<<SOURCE).strip
<a href='http://www.cnet.com/'>download</a>
<a href='http://www.yahoo.com/test/'>yahoo</a>
SOURCE

      expect(links.size).to eq(1)
    end
  end

  describe '#parse_internal_visitable' do
    let(:page) { Retriever::Page.new('http://www.cnet.com/', @source, t) }
    let(:links) { page.parse_internal_visitable }
    it "filters out 'unvisitable' URLS like JS, Stylesheets, Images" do
      @source = (<<SOURCE).strip
 <link rel='stylesheet' id='gforms_reset_css-css'  href='http://www.cnet.com/wp-content/plugins/gravityforms/css/formreset.css?ver=1.7.12' type='text/css' media='all' />
SOURCE
      expect(links.size).to eq(0)
    end
  end

  describe '#parse_files' do
    let(:page) { Retriever::Page.new('http://www.cnet.com/', @source, t) }
    let(:files) { page.parse_files(page.parse_internal) }
    it 'filters links by filetype' do
      @source = (<<SOURCE).strip
<a href='www.cnet.com/download.exe'>download</a>
http://www.google.com
<a href='/test.html'>test</a>
SOURCE
      expect(files.size).to eq(1)
    end
  end

  describe '#title' do
    let(:page) { Retriever::Page.new('http://www.cnet.com/', @source, t) }
    it 'returns page title' do
      @source = (<<SOURCE).strip
<title>test</title>
SOURCE
      expect(page.title).to eq('test')
    end
  end
  describe '#desc' do
    let(:page) { Retriever::Page.new('http://www.cnet.com/', @source, t) }
    it 'returns meta description' do
      @source = (<<SOURCE).strip
<meta name='description' content="test2 ">
SOURCE
      expect(page.desc).to eq('test2 ')
    end
  end
  describe '#h1' do
    let(:page) { Retriever::Page.new('http://www.cnet.com/', @source, t) }
    it 'returns h1 text' do
      @source = (<<SOURCE).strip
<h1>test 3</h1>
SOURCE
      expect(page.h1).to eq('test 3')
    end
  end
  describe '#h2' do
    let(:page) { Retriever::Page.new('http://www.cnet.com/', @source, t) }
    it 'returns h2 text' do
      @source = (<<SOURCE).strip
<h2> test 4 </h2>
SOURCE
      expect(page.h2).to eq(' test 4 ')
    end
  end
end
