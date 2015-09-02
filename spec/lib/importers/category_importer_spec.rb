require 'rails_helper'
require "#{Rails.root}/lib/importers/category_importer"

describe CategoryImporter do
  it 'should import data for articles in a category' do
    VCR.use_cassette 'category_importer/import' do
      CategoryImporter
        .import_category('Category:"Crocodile" Dundee')
      expect(Article.exists?(title: 'Michael_"Crocodile"_Dundee'))  # depth 0
        .to be true
      expect(Article.exists?(title: 'Crocodile_Dundee_in_Los_Angeles'))  # depth 1
        .to be false
    end
  end

  it 'should import subcategories recursively' do
    VCR.use_cassette 'category_importer/import' do
      CategoryImporter
        .import_category('Category:"Crocodile" Dundee', 1)
      expect(Article.exists?(title: 'Michael_"Crocodile"_Dundee')) # depth 0
        .to be true
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

  it 'should pull importin missing data for category' do
    VCR.use_cassette 'category_importer/report_on_category_incomplete' do
      output = CategoryImporter
               .report_on_category('Category:"Crocodile" Dundee')
      expect(output).to include 'Michael_"Crocodile"_Dundee'
    end
  end
end
