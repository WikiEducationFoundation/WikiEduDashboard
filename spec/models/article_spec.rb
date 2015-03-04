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
    it 'should get the url for an article' do
      article = build(:article, title: 'Selfie')
      expect(article.url).to eq('https://en.wikipedia.org/wiki/Selfie')
      
      sandbox = build(:article, namespace: 2, title: 'Ragesoss/sandbox')
      expect(sandbox.url).to eq('https://en.wikipedia.org/wiki/User:Ragesoss/sandbox')
      
      draft = build(:article, namespace: 118, title: 'My Awesome Draft!!!')
      expect(draft.url).to eq('https://en.wikipedia.org/wiki/Draft:My_Awesome_Draft!!!')
    end
  end

end
