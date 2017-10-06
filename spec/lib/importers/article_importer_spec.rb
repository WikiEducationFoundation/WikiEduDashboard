# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/importers/article_importer"

describe ArticleImporter do
  before { stub_wiki_validation }
  let(:en_wiki) { Wiki.default_wiki }
  let(:es_wiki) { create(:wiki, language: 'es', project: 'wikipedia') }

  describe '.import_articles' do
    it 'creates an Article from a English Wikipedia page_id' do
      ArticleImporter.new(en_wiki).import_articles [46349871]
      article = Article.find_by(mw_page_id: 46349871)
      expect(article.title).to eq('Kostanay')
    end

    it 'works for a language besides the default' do
      ArticleImporter.new(es_wiki).import_articles [100]
      article = Article.find_by(mw_page_id: 100)
      expect(article.title).to eq('Alnus')
    end
  end

  describe '.import_articles_by_title' do
    it 'creates an Article from a title with the correct mw_page_id' do
      titles = %w[Selfie Bombus_hortorum Kostanay]
      VCR.use_cassette 'article_importer/existing_titles' do
        ArticleImporter.new(en_wiki).import_articles_by_title(titles)
      end
      expect(Article.find_by(title: 'Kostanay').mw_page_id).to eq(46349871)
    end

    it 'does not create an article if there is no matching title' do
      titles = ['There_is_no_article_with_this_title']
      VCR.use_cassette 'article_importer/nonexistent_title' do
        ArticleImporter.new(en_wiki).import_articles_by_title(titles)
      end
      expect(Article.find_by(title: titles[0])).to be_nil
    end

    it 'works for a language besides the default' do
      VCR.use_cassette 'article_importer/existing_titles' do
        titles = %w[Selfie Bombus_hortorum]
        ArticleImporter.new(es_wiki).import_articles_by_title(titles)
        expect(Article.find_by(title: 'Selfie').mw_page_id).to eq(6210294)
      end
    end
  end
end
