# frozen_string_literal: true

require 'rails_helper'

describe ClaimVerificationHelper, type: :helper do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }

  describe '#claim_article_url' do
    it 'links to the flagged revision the claim came from, at its footnote' do
      claim = VerificationClaim.new(wiki:, article_title: 'Sea_otter', mw_rev_id: 777,
                                    ref_id: 'cite_note-1', sentence: 'Otters use tools.')
      expect(helper.claim_article_url(claim))
        .to eq('https://en.wikipedia.org/w/index.php?oldid=777#cite_note-1')
    end

    it 'falls back to the current article for a claim with no recorded revision' do
      claim = VerificationClaim.new(wiki:, article_title: 'Sea_otter',
                                    sentence: 'Otters use tools.')
      expect(helper.claim_article_url(claim)).to eq('https://en.wikipedia.org/wiki/Sea_otter')
    end

    it 'is nil with neither a revision nor a title' do
      claim = VerificationClaim.new(wiki:, sentence: 'Otters use tools.')
      expect(helper.claim_article_url(claim)).to be_nil
    end
  end
end
