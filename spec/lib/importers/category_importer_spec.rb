require 'rails_helper'
require "#{Rails.root}/lib/importers/category_importer"

describe CategoryImporter do
  it 'should import data for articles in a category' do
    VCR.use_cassette 'category_importer/import' do
      CategoryImporter.import_category('Category:Dark Web')
      expect(Article.exists?(title: 'Tor_(anonymity_network)')).to be true
      expect(Article.exists?(title: 'Guy_Fawkes_mask')).to be false # depth 2
    end
  end

  it 'should import subcategories recursively' do
    VCR.use_cassette 'category_importer/import' do
      CategoryImporter.import_category('Category:Dark Web', 2)
      expect(Article.exists?(title: 'Tor_(anonymity_network)')) # depth 0
        .to be true
      expect(Article.exists?(title: 'Riseup')).to be true # depth 1
      expect(Article.exists?(title: 'Guy_Fawkes_mask')).to be true # depth 2
    end
  end

  it 'should output filtered data about a category' do
    VCR.use_cassette 'category_importer/import' do
      CategoryImporter.import_category('Category:Dark Web', 2)
    end

    VCR.use_cassette 'category_importer/report_on_category' do
      output = CategoryImporter.report_on_category('Category:Dark Web')
      expect(output).to include 'Tor_(anonymity_network)'
    end
  end
end
