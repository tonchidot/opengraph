# coding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe OpenGraph do
  let(:rotten){ File.open(File.dirname(__FILE__) + '/examples/rottentomatoes.html').read }
  let(:partial){ File.open(File.dirname(__FILE__) + '/examples/partial.html').read }
  
  describe '.parse' do
    it 'should return false if there isnt valid Open Graph info' do
      OpenGraph.parse("").should be_false
      OpenGraph.parse(partial).should be_false
    end
    
    it 'should otherwise return an OpenGraph::Object' do
      OpenGraph.parse(rotten).should be_kind_of(OpenGraph::Object)
    end
    
    context ' without strict mode' do
      subject{ OpenGraph.parse(partial, false) }
      
      it { should_not be_false }
      it { subject.title.should == 'Partialized' }
    end
  end
  
  describe '.fetch' do

    it 'should fetch from the specified URL' do
      stub_request(:get, 'http://www.rottentomatoes.com/m/1217700-kick_ass/').to_return(:body => rotten)
      OpenGraph.fetch('http://www.rottentomatoes.com/m/1217700-kick_ass/').title.should == 'Kick-Ass'
      WebMock.should have_requested(:get, 'http://www.rottentomatoes.com/m/1217700-kick_ass/')
    end
    
    it 'should catch errors' do
      stub_request(:get, 'http://example.com').to_return(:status => 404)
      OpenGraph.fetch('http://example.com').should be_false
      OpenGraph.should_receive(:open).with('http://example.com').and_raise(SocketError)
      OpenGraph.fetch('http://example.com').should be_false
    end

    describe 'encoding' do
      let(:uri) { 'http://example.com/non-utf-8.html' }
      let(:non_utf8){ File.open(File.dirname(__FILE__) + '/examples/tab-euc-jp.html').read }
      before do
        stub_request(:get, uri).to_return(:headers => { 'Content-Type' => 'text/html; charset=EUC-JP' }, :body => non_utf8)
      end
      it 'should return utf-8 string even non utf-8' do
        OpenGraph.fetch(uri).title.should == 'STARTER Kit - THE COFFEESHOP（ザ・コーヒーショップ）／ONLINE STORE（オンラインストア）'
      end
    end
  end
end

describe OpenGraph::Object do
  let(:rotten){ File.open(File.dirname(__FILE__) + '/examples/rottentomatoes.html')}
  let(:tab){ File.open(File.dirname(__FILE__) + '/examples/tab.html').read }
  
  context ' a Rotten Tomatoes Movie' do
    subject{ OpenGraph.parse(rotten) }
    
    it 'should have the title' do
      subject.title.should == "Kick-Ass"
    end
    
    it 'should be a product' do
      subject.schema.should == 'product'
      subject.should be_product
      subject.should_not be_person
    end
    
    it 'should be a movie' do
      subject.type.should == 'movie'
      subject.should be_movie
      subject.should_not be_tv_show
    end
    
    it 'should be valid' do
      subject.should be_valid
      subject['type'] = nil
      subject.should_not be_valid
    end
  end

  context 'tab' do
    subject{ OpenGraph.parse(tab) }

    its(['tab:place:name']) { should == '頓智ドット' }
    its(['tab:place:address']) { should == '東京都渋谷区渋谷1-11-1 COI 西青山ビル7F' }
    its(['tab:place:latitude']) { should == '35.661104' }
    its(['tab:place:longitude']) { should == '139.704424' }
  end
end
