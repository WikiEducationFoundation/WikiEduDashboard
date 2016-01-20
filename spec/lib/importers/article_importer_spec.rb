require 'rails_helper'
require "#{Rails.root}/lib/importers/article_importer"

describe ArticleImporter do
  describe '.import_articles' do
    it 'should create an Article from a Wikipedia page_id' do
      ArticleImporter.import_articles [46349871]
      article = Article.find(46349871)
      expect(article.title).to eq('Kostanay')
    end
  end

  describe '.import_articles_by_title' do
    it 'should create an Article from a title' do
      titles = %w(Selfie Bombus_hortorum)
      VCR.use_cassette 'article_importer/existing_titles' do
        ArticleImporter.import_articles_by_title(titles)
      end
      expect(Article.find_by(title: 'Selfie')).to be_a(Article)
    end
    it 'should not create an article if there is no matching title' do
      titles = ['There_is_no_article_with_this_title']
      VCR.use_cassette 'article_importer/nonexistent_title' do
        ArticleImporter.import_articles_by_title(titles)
      end
      expect(Article.find_by(title: titles[0])).to be_nil
    end
  end
end
