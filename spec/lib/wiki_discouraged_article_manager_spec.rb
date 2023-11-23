# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/wiki_discouraged_article_manager"

describe WikiDiscouragedArticleManager do
  describe '#retrieve_wiki_edu_discouraged_articles' do
    context 'when updating an existing category' do
      let(:category_title) { 'TestCategory' }
      let!(:existing_category) do
        create(:category, name: category_title, article_titles: %w[Article1 Article2])
      end

      before do
        category_importer = instance_double(CategoryImporter)
        allow(CategoryImporter).to receive(:new).and_return(category_importer)
        allow(category_importer).to receive(:page_titles_for_category)
                                .and_return(%w[Article3 Article4])
        ENV['blocked_assignment_category'] = category_title
      end

      it 'updates existing category with new article titles' do
        expect { subject.retrieve_wiki_edu_discouraged_articles }.to change {
          existing_category.reload.article_titles
        }.to(%w[Article3 Article4])
      end
    end

    context 'when creating a new category' do
      let(:category_title) { 'TestCategory' }

      before do
        category_importer = instance_double(CategoryImporter)
        allow(CategoryImporter).to receive(:new).and_return(category_importer)
        allow(category_importer).to receive(:page_titles_for_category)
                                .and_return(%w[Article1 Article2])
        ENV['blocked_assignment_category'] = category_title
      end

      it 'creates a new category in the database' do
        expect { subject.retrieve_wiki_edu_discouraged_articles }.to change(Category, :count).by(1)
      end

      it 'sets the correct article titles for the new category' do
        subject.retrieve_wiki_edu_discouraged_articles
        new_category = Category.find_by(name: category_title)
        expect(new_category.article_titles).to eq(%w[Article1 Article2])
      end
    end
  end
end
