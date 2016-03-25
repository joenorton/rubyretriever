require 'retriever/page'
require 'retriever/fetch'

t = Retriever::Target.new('http://www.cnet.com/reviews/', /\.exe\z/)

describe 'Page' do
  let(:common_source) do
    <<-SOURCE
    <title>test</title>
    <a href='www.cnet.com/download.exe'>download</a>
    <a href='/test.html'>test</a>
    <a href='http://www.cnet.com/products/gadgets/' data-vanity-rewritten='true'>
    </a>
    <a href='http://www.cnet.com/products/gadgets/' id='gadgets-link'>gadgets </a>
    <a href='http://www.yahoo.com/test/'>yahoo</a>"
    <meta name='description' content="test2 ">
    <h1>test 3</h1>
    <h2> test 4 </h2>
    SOURCE
  end

  describe '#url' do
    let(:page) { Retriever::Page.new('http://www.cnet.com/', common_source, t) }
    it 'returns current page URL' do
      expect(page.url).to eq('http://www.cnet.com/')
    end
  end

  describe '#links' do
    let(:source) { "<a href='/profile/'>profile</a><a href='#top'>top</a> <link rel='stylesheet' id='gforms_reset_css-css'  href='http://www.cnet.com/wp-content/plugins/gravityforms/css/formreset.css?ver=1.7.12' type='text/css' media='all' />" }
    let(:page) { Retriever::Page.new('http://www.cnet.com/', source, t) }
    it 'collects all unique href links on the page, skips div anchors' do
      expect(page.links.size).to eq(2)
    end
  end

  describe '#parse_internal' do
    let(:page) { Retriever::Page.new('http://www.cnet.com/', common_source, t) }
    let(:links) { page.parse_internal }
    it 'filters links by host' do
      expect(links.size).to eq(3)
    end
  end

  describe '#parse_internal_visitable' do
    let(:source) { "<a href='/profile/'>profile</a> <link rel='stylesheet' id='gforms_reset_css-css'  href='http://www.cnet.com/wp-content/plugins/gravityforms/css/formreset.css?ver=1.7.12' type='text/css' media='all' />" }
    let(:page) { Retriever::Page.new('http://www.cnet.com/', source, t) }
    let(:links) { page.parse_internal_visitable }
    it "filters out 'unvisitable' URLS like JS, Stylesheets, Images" do
      expect(links.size).to eq(1)
    end
  end

  describe '#parse_files' do
    let(:page) { Retriever::Page.new('http://www.cnet.com/', common_source, t) }
    let(:files) { page.parse_files(page.parse_internal) }
    it 'filters links by filetype' do
      expect(files.size).to eq(1)
    end
  end

  describe '#parse_by_css' do
    let(:page) { Retriever::Page.new('http://www.cnet.com/', common_source, t) }

    it 'returns the text from the received css selector' do
      expect(page.parse_by_css('#gadgets-link')).to eq('gadgets ')
    end
  end

  describe '#title' do
    let(:page) { Retriever::Page.new('http://www.cnet.com/', common_source, t) }
    it 'returns page title' do
      expect(page.title).to eq('test')
    end
  end
  describe '#desc' do
    let(:page) { Retriever::Page.new('http://www.cnet.com/', common_source, t) }
    it 'returns meta description' do
      expect(page.desc).to eq('test2 ')
    end
  end
  describe '#h1' do
    let(:page) { Retriever::Page.new('http://www.cnet.com/', common_source, t) }
    it 'returns h1 text' do
      expect(page.h1).to eq('test 3')
    end
  end
  describe '#h2' do
    let(:page) { Retriever::Page.new('http://www.cnet.com/', common_source, t) }
    it 'returns h2 text' do
      expect(page.h2).to eq(' test 4 ')
    end
  end
end
