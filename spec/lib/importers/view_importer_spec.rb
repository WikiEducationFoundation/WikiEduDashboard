require 'rails_helper'
require "#{Rails.root}/lib/importers/view_importer"

describe ViewImporter do
  describe '.update_views_for_article' do
    it 'should not fail if there are no revisions for an article' do
      article = create(:article,
                       title: 'Selfie',
                       views_updated_at: '2015-01-01')
      ViewImporter.update_views_for_article(article)
    end
  end
end
