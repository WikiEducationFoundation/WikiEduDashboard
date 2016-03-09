require 'rails_helper'
require "#{Rails.root}/lib/importers/article_importer"

describe DuplicateArticleDeleter do
  describe '.resolve_duplicates' do
    it 'should handle cases where there are two ids for one page' do
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
        deleted: false)
      expect(undeleted.count).to eq(1)
      expect(undeleted.first.id).to eq(second.id)
    end
  end
end
