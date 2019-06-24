# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/importers/category_importer"

describe CategoryImporter do
  let(:wiki) { Wiki.default_wiki }
  let(:subject) { described_class.new(wiki).page_titles_for_category(category, depth) }

  describe '.page_titles_for_category' do
    context 'for depth 0' do
      let(:category) { 'Category:AfD debates' }
      let(:depth) { 0 }

      it 'returns page page titles for a given category' do
        VCR.use_cassette 'category_importer/page_titles' do
          expect(subject).to include('Category:AfD debates (Places and transportation)')
        end
      end
    end

    context 'for depth 1' do
      let(:category) { 'Category:Crocodile Dundee' }
      let(:article_in_cat) { 'Michael "Crocodile" Dundee' }
      let(:article_in_subcat) { 'Crocodile Dundee in Los Angeles' }
      let(:depth) { 1 }

      it 'works recursively for subcategories' do
        VCR.use_cassette 'category_importer/page_titles' do
          expect(subject).to include(article_in_cat)
          expect(subject).to include(article_in_subcat)
        end
      end
    end
  end
end
