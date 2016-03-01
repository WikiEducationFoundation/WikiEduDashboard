require 'rails_helper'
require "#{Rails.root}/lib/importers/category_importer"

describe CategoryImporter do
  it 'should import data for articles in a category' do
    VCR.use_cassette 'category_importer/import' do
      CategoryImporter.new(Wiki.default_wiki)
        .import_category('Category:"Crocodile" Dundee')
      expect(Article.exists?(title: 'Michael_"Crocodile"_Dundee'))
        .to be true # depth 0
      expect(Article.exists?(title: 'Crocodile_Dundee_in_Los_Angeles'))
        .to be false # depth 1
    end
  end

  it 'should import subcategories recursively' do
    VCR.use_cassette 'category_importer/import' do
      CategoryImporter.new(Wiki.default_wiki)
        .import_category('Category:"Crocodile" Dundee', 1)
      expect(Article.exists?(title: 'Michael_"Crocodile"_Dundee'))
        .to be true # depth 0
      expect(Article.exists?(title: 'Crocodile_Dundee_in_Los_Angeles'))
        .to be true # depth 1
    end
  end

  it 'should output filtered data about a category' do
    VCR.use_cassette 'category_importer/import' do
      CategoryImporter.new(Wiki.default_wiki)
        .import_category('Category:"Crocodile" Dundee', 1)
    end
    VCR.use_cassette 'category_importer/report_on_category' do
      output = CategoryImporter.new(Wiki.default_wiki)
               .report_on_category('Category:"Crocodile" Dundee')
      expect(output).to include 'Michael_"Crocodile"_Dundee'
    end
  end

  it 'should import missing data for category' do
    VCR.use_cassette 'category_importer/report_on_category_incomplete' do
      output = CategoryImporter.new(Wiki.default_wiki)
               .report_on_category('Category:"Crocodile" Dundee')
      expect(output).to include 'Michael_"Crocodile"_Dundee'
    end
  end

  describe '.show_category' do
    it 'should return the articles in a category' do
      # Create an article ahead of time, to make sure we handle both articles
      # that we already have and ones we don't.
      create(:article,
             id: 10670306,
             title: 'Michael_"Crocodile"_Dundee')
      VCR.use_cassette 'category_importer/import' do
        results = CategoryImporter.new(Wiki.default_wiki)
                  .show_category('Category:"Crocodile" Dundee', depth: 1)
        article = Article.find_by(title: 'Michael_"Crocodile"_Dundee')
        expect(results).to include article
      end
    end
  end
end
