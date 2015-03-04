require 'rails_helper'

describe Article do
  describe '.update' do
    it 'should do a null update for an article' do
      VCR.use_cassette 'article/article_data' do
        article = build(:article)
        article.update
      end
    end  
  end

  describe '.url' do
    it 'get the url for an article' do
      article = build(:article)
      expect(article.url).to eq('https://en.wikipedia.org/wiki/History_of_biology')
    end
  end

end
