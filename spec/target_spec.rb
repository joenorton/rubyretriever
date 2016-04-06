require 'retriever'
require 'open-uri'

describe 'Target' do
  let(:t) do
    Retriever::Target.new('http://www.cnet.com/reviews/', /\.exe\z/)
  end

  it 'creates target var' do
    expect(t.target).to eq('http://www.cnet.com/reviews/')
  end

  it 'creates host var' do
    expect(t.host).to eq('www.cnet.com')
  end

  it 'creates host_re var' do
    expect(t.host_re).to eq(/cnet.com/)
  end

  it 'creates port var (no port specified)' do
    expect(t.port).to be_nil
  end

  it 'creates port var (with port specified)' do
    expect(Retriever::Target.new('http://www.cnet.com:3000/reviews/', /\.exe\z/).port).to be(3000)
  end

  it 'creates file_re var (when provided)' do
    expect(t.file_re).to eq(/\.exe\z/)
  end

  it 'adds protocol to Target URL if none given' do
    expect(Retriever::Target.new('cnet.com').target).to eq('http://cnet.com')
  end

  it 'fails if given URL has no dot in it' do
    expect { Retriever::Target.new('cnetcom') }.to raise_error
  end

  describe '#source' do
    let(:redirecting_url) do
      Retriever::Target.new('http://software-by-joe.appspot.com').source
    end

    it 'opens URL and returns source as String' do
      expect(Retriever::Target.new('http://techcrunch.com/').source.class)
      .to eq(String)
    end

    it 'fails if target redirects to new host' do
      expect { redirecting_url }.to raise_error
    end
  end
end
