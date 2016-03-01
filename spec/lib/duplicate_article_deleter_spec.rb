require 'rails_helper'
require "#{Rails.root}/lib/importers/article_importer"

describe DuplicateArticleDeleter do
  describe '.resolve_duplicates' do
    it 'should handle cases where there are two ids for one page' do
      first = create(:article,
                     mw_page_id: 2262715,
                     title: 'Kostanay',
                     namespace: 0)
      second = create(:article,
                      mw_page_id: 46349871,
                      title: 'Kostanay',
                      namespace: 0)
      DuplicateArticleDeleter.resolve_duplicates([first])
      undeleted = Article.where(
        title: 'Kostanay',
        namespace: 0,
        deleted: false)
      expect(undeleted.count).to eq(1)
      expect(undeleted.first.mw_page_id).to eq(second.mw_page_id)
    end
  end
end
