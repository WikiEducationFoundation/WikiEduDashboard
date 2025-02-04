# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/importers/category_importer"

describe CategoryImporter do
  let(:wiki) { Wiki.default_wiki }
  let(:subject) { described_class.new(wiki).page_titles_for_category(category, depth) }

  describe '.page_titles_for_category' do
    context 'for depth 0' do
      let(:category) { 'Category:Earth sciences' }
      let(:depth) { 0 }

      it 'returns page page titles for a given category' do
        VCR.use_cassette 'cached/category_importer/page_titles' do
          # this is a direct article in the category
          expect(subject).to include('List of flood basalt provinces')

          # this is a subcategory which should not be included
          expect(subject).not_to include('Category: Earth scientists')
          expect(subject).not_to include('Category:Earth sciences')
        end
      end
    end

    context 'for depth 1' do
      let(:category) { 'Category:Monty Python' }
      let(:article_in_cat) { 'Monty Python v. American Broadcasting Companies, Inc.' }
      let(:article_in_subcat) { "Monty Python's Life of Brian" }
      let(:depth) { 1 }

      it 'works recursively for subcategories' do
        VCR.use_cassette 'cached/category_importer/page_titles' do
          expect(subject).to include(article_in_cat)
          expect(subject).to include(article_in_subcat)

          # this is a subcategory which should not be included
          expect(subject).not_to include('Category:Monty Python members')
        end
      end
    end
  end
end
