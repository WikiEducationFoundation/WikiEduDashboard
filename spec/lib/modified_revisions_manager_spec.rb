# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/modified_revisions_manager"

describe ModifiedRevisionsManager do
  describe '.move_or_delete_revisions' do
    it 'updates the article_id for a moved revision' do
      # https://en.wikipedia.org/w/index.php?title=Selfie&oldid=547645475
      create(:revision,
             mw_rev_id: 547645475,
             mw_page_id: 1,
             article_id: 1) # Not the actual article_id
      revision = Revision.all
      described_class.new(Wiki.default_wiki).move_or_delete_revisions(revision)
      article = Revision.find_by(mw_rev_id: 547645475).article
      expect(article.mw_page_id).to eq(38956275)
      expect(Article.exists?(mw_page_id: 38956275)).to be true
    end
  end
end
