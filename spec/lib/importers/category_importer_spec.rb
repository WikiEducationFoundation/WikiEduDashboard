require 'rails_helper'
require "#{Rails.root}/lib/importers/category_importer"

describe CategoryImporter do
  it 'should import data for articles in a category' do
    VCR.use_cassette 'category_importer/import' do
      CategoryImporter
        .import_category('Category:"Crocodile" Dundee')
      expect(Article.exists?(title: 'Michael_"Crocodile"_Dundee'))
        .to be true # depth 0
      expect(Article.exists?(title: 'Crocodile_Dundee_in_Los_Angeles'))
        .to be false # depth 1
    end
  end

  it 'should import subcategories recursively' do
    VCR.use_cassette 'category_importer/import' do
      CategoryImporter
        .import_category('Category:"Crocodile" Dundee', 1)
      expect(Article.exists?(title: 'Michael_"Crocodile"_Dundee'))
        .to be true # depth 0
      expect(Article.exists?(title: 'Crocodile_Dundee_in_Los_Angeles'))
        .to be true # depth 1
    end
  end

  it 'should output filtered data about a category' do
    VCR.use_cassette 'category_importer/import' do
      CategoryImporter
        .import_category('Category:"Crocodile" Dundee', 1)
    end
    VCR.use_cassette 'category_importer/report_on_category' do
      output = CategoryImporter
               .report_on_category('Category:"Crocodile" Dundee')
      expect(output).to include 'Michael_"Crocodile"_Dundee'
    end
  end

  it 'should import missing data for category' do
    VCR.use_cassette 'category_importer/report_on_category_incomplete' do
      output = CategoryImporter
               .report_on_category('Category:"Crocodile" Dundee')
      expect(output).to include 'Michael_"Crocodile"_Dundee'
    end
  end

  describe '.show_category' do
    it 'should return the articles in a category' do
      VCR.use_cassette 'category_importer/import' do
        results = CategoryImporter.show_category('Category:"Crocodile" Dundee')
        article = Article.find_by(title: 'Michael_"Crocodile"_Dundee')
        expect(results).to include article
      end
    end
  end
end
