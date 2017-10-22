# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/importers/category_importer"

describe CategoryImporter do
  let(:category) { 'Category:Crocodile Dundee' }
  let(:article_in_cat) { 'Michael_"Crocodile"_Dundee' }
  let(:article_in_subcat) { 'Crocodile_Dundee_in_Los_Angeles' }
  let(:wiki) { Wiki.default_wiki }

  it 'imports data for articles in a category' do
    VCR.use_cassette 'category_importer/import' do
      CategoryImporter.new(wiki)
                      .import_category(category)
      expect(Article.exists?(title: article_in_cat))
        .to be true # depth 0
      expect(Article.exists?(title: article_in_subcat))
        .to be false # depth 1
    end
  end

  it 'imports subcategories recursively' do
    VCR.use_cassette 'category_importer/import' do
      pending 'This sometimes fails on travis for database timeout reasons.'

      CategoryImporter.new(wiki, depth: 1)
                      .import_category(category)
      expect(Article.exists?(title: article_in_cat))
        .to be true # depth 0
      expect(Article.exists?(title: article_in_subcat))
        .to be true # depth 1

      puts 'PASSED'
      raise 'this test passed — this time'
    end
  end

  it 'outputs filtered data about a category' do
    VCR.use_cassette 'category_importer/import' do
      CategoryImporter.new(wiki, depth: 1)
                      .import_category(category)
    end
    VCR.use_cassette 'category_importer/report_on_category' do
      output = CategoryImporter.new(wiki)
                               .report_on_category(category)
      expect(output).to include article_in_cat
    end
  end

  it 'imports missing data for category' do
    VCR.use_cassette 'category_importer/report_on_category_incomplete' do
      output = CategoryImporter.new(wiki)
                               .report_on_category(category)
      expect(output).to include article_in_cat
    end
  end

  describe '.show_category' do
    it 'should return the articles in a category' do
      # Create an article ahead of time, to make sure we handle both articles
      # that we already have and ones we don't.
      create(:article,
             id: 10670306,
             mw_page_id: 10670306,
             title: 'Michael_"Crocodile"_Dundee')
      VCR.use_cassette 'category_importer/import' do
        results = CategoryImporter.new(wiki, depth: 1)
                                  .show_category(category)
        article = Article.find_by(title: article_in_cat)
        expect(results).to include article
      end
    end
  end

  describe '.page_titles_for_category' do
    let(:category) { 'Category:AfD debates' }
    let(:depth) { 0 }
    let(:subject) { described_class.new(wiki).page_titles_for_category(category, depth) }

    it 'returns page page titles for a given category' do
      VCR.use_cassette 'category_importer/page_titles' do
        expect(subject).to include('Category:AfD debates (Places and transportation)')
      end
    end
  end
end
