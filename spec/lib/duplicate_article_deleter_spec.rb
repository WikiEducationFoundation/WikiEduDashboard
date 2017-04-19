# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/importers/article_importer"

describe DuplicateArticleDeleter do
  describe '.resolve_duplicates' do
    it 'marks one deleted when there are two ids for one page' do
      first = create(:article,
                     id: 2262715,
                     title: 'Kostanay',
                     namespace: 0)
      second = create(:article,
                      id: 46349871,
                      title: 'Kostanay',
                      namespace: 0)
      DuplicateArticleDeleter.new.resolve_duplicates([first])
      undeleted = Article.where(
        title: 'Kostanay',
        namespace: 0,
        deleted: false
      )
      expect(undeleted.count).to eq(1)
      expect(undeleted.first.id).to eq(second.id)
    end

    it 'does not mark any deleted when articles different in title case' do
      first = create(:article,
                     id: 123,
                     title: 'Communicative_language_teaching',
                     namespace: 0)
      second = create(:article,
                      id: 456,
                      title: 'Communicative_Language_Teaching',
                      namespace: 0)
      DuplicateArticleDeleter.new.resolve_duplicates([first, second])
      expect(first.reload.deleted).to eq(false)
      expect(second.reload.deleted).to eq(false)
    end
  end
end
