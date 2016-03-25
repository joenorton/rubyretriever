require 'retriever'
require 'retriever/fetchfiles'

describe 'Fetch' do
  let(:r) do
    Retriever::Fetch.new('http://www.yahoo.com', {})
  end
  describe '#good_response?' do

    let(:resp) do
      {}
    end

    let(:nil_response) do
      r.good_response?(nil, 'http://www.yahoo.com')
    end

    let(:unsuccessful_resp) do
      resp.stub(:response_header).and_return(resp)
      resp.stub(:redirection?).and_return(false)
      resp.stub(:successful?).and_return(false)
      resp.stub(:server_error?).and_return(false)
      resp.stub(:client_error?).and_return(false)
      r.good_response?(resp, 'http://www.yahoo.com')
    end

    let(:redir_resp) do
      resp.stub(:response_header).and_return(resp)
      resp.stub(:redirection?).and_return(true)
      resp.stub(:location).and_return('http://www.google.com')
      r.good_response?(resp, 'http://www.yahoo.com')
    end

    let(:bad_content_type_resp) do
      resp.stub(:response_header).and_return(resp)
      resp.stub(:redirection?).and_return(false)
      resp.stub(:successful?).and_return(true)
      resp['CONTENT_TYPE'] = 'image/jpeg'
      r.good_response?(resp, 'http://www.yahoo.com')
    end

    let(:success_resp) do
      resp.stub(:response_header).and_return(resp)
      resp.stub(:redirection?).and_return(false)
      resp.stub(:successful?).and_return(true)
      resp['CONTENT_TYPE'] = 'text/html'
      r.good_response?(resp, 'http://www.yahoo.com')
    end

    it 'returns false if the response is empty' do
      expect(nil_response).to eq(false)
    end

    it 'returns false on unsuccessful connection' do
      expect(unsuccessful_resp).to eq(false)
    end

    it 'returns false on redirecting host' do
      expect(redir_resp).to eq(false)
    end

    it 'returns false on non-visitable content type' do
      expect(bad_content_type_resp).to eq(false)
    end

    it 'returns true otherwise' do
      expect(success_resp).to eq(true)
    end
  end
  describe '#filter_out_querystrings' do
    let(:normal_url) do
      r.filter_out_querystrings('http://mises.org/test.mp3')
    end
    let(:query_string_url) do
      r.filter_out_querystrings('http://mises.org/system/tdf/Robert%20Nozick%20and%20Murray%20Rothbard%20David%20Gordon.mp3?file=1&amp;type=audio')
    end
    it 'accepts standard urls' do
      expect(normal_url).to eq('http://mises.org/test.mp3')
    end
    it 'strips query params' do
      expect(query_string_url).to eq('http://mises.org/system/tdf/Robert%20Nozick%20and%20Murray%20Rothbard%20David%20Gordon.mp3')
    end
  end
end
