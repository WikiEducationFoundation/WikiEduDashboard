# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/wiki_discouraged_article_manager"

describe WikiDiscouragedArticleManager do
  describe '#retrieve_wiki_edu_discouraged_articles' do
    it 'calls update_or_create_discouraged_articles method' do
      manager = described_class.new
      expect(manager).to receive(:update_or_create_discouraged_articles)
      manager.retrieve_wiki_edu_discouraged_articles
    end
  end

  describe '#update_or_create_discouraged_articles' do
    it 'finds or creates a category and refreshes titles' do
      allow(Category).to receive(:find_or_create_by)
                     .and_return(instance_double(Category, refresh_titles: true))

      manager = described_class.new
      expect(manager.send(:update_or_create_discouraged_articles)).to be_truthy
    end

    it 'calls en_wiki method to get the Wiki' do
      manager = described_class.new
      allow(manager).to receive(:en_wiki).and_return(instance_double(Wiki, id: 1))

      allow(Category).to receive(:find_or_create_by)
                     .and_return(instance_double(Category, refresh_titles: true))

      expect(manager.send(:update_or_create_discouraged_articles)).to be_truthy
    end
  end
end
