# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/importers/article_importer"

describe ArticleImporter do
  before { stub_wiki_validation }

  let(:en_wiki) { Wiki.default_wiki }
  let(:es_wiki) { create(:wiki, language: 'es', project: 'wikipedia') }

  describe '.import_articles' do
    it 'creates an Article from a English Wikipedia page_id' do
      VCR.use_cassette 'article_importer/article_importer' do
        described_class.new(en_wiki).import_articles [46349871]
        article = Article.find_by(mw_page_id: 46349871)
        expect(article.title).to eq('Kostanay')
      end
    end

    it 'works for a language besides the default' do
      VCR.use_cassette 'article_importer/article_importer' do
        described_class.new(es_wiki).import_articles [100]
        article = Article.find_by(mw_page_id: 100)
        expect(article.title).to eq('Alnus')
      end
    end
  end

  describe '.import_articles_by_title' do
    it 'creates an Article from a title with the correct mw_page_id' do
      titles = %w[Selfie Bombus_hortorum Kostanay]
      VCR.use_cassette 'article_importer/existing_titles' do
        described_class.new(en_wiki).import_articles_by_title(titles)
      end
      expect(Article.find_by(title: 'Kostanay').mw_page_id).to eq(46349871)
    end

    it 'does not create an article if there is no matching title' do
      titles = ['There_is_no_article_with_this_title']
      VCR.use_cassette 'article_importer/nonexistent_title' do
        described_class.new(en_wiki).import_articles_by_title(titles)
      end
      expect(Article.find_by(title: titles[0])).to be_nil
    end

    it 'does not create an article if the title is invalid' do
      titles = ['Title_with_[illegal]_characters']
      VCR.use_cassette 'article_importer/invalid_title' do
        described_class.new(en_wiki).import_articles_by_title(titles)
      end
      expect(Article.find_by(title: titles[0])).to be_nil
    end

    it 'works for a language besides the default' do
      VCR.use_cassette 'article_importer/existing_titles' do
        titles = %w[Selfie Bombus_hortorum]
        described_class.new(es_wiki).import_articles_by_title(titles)
        expect(Article.find_by(title: 'Selfie').mw_page_id).to eq(6210294)
      end
    end

    it 'updates the title if the article with that mw_page_id exists already' do
      create(:article, title: 'Constantinople', mw_page_id: 3391396)
      VCR.use_cassette 'article_importer/collisions' do
        described_class.new(en_wiki).import_articles_by_title(['Istanbul'])
        expect(Article.find_by(title: 'Istanbul').mw_page_id).to eq(3391396)
      end
    end
  end
end
