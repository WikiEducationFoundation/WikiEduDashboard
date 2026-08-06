# frozen_string_literal: true

require 'rails_helper'
require_dependency "#{Rails.root}/lib/claim_verification/rollout_list"

describe ClaimVerification::RolloutList do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }

  def claim(article_id:, mw_rev_id:)
    VerificationClaim.create!(wiki:, article_id:, mw_rev_id:, sentence: 'A fact.')
  end

  describe '.filter' do
    it 'keeps only claims on a listed (article, revision) pair' do
      listed = claim(article_id: 1, mw_rev_id: 100)
      claim(article_id: 2, mw_rev_id: 200)
      rollout_revisions([1, 100])
      expect(described_class.filter(VerificationClaim.all)).to eq([listed])
    end

    it 'excludes a listed revision id under a different article' do
      claim(article_id: 2, mw_rev_id: 100)
      rollout_revisions([1, 100])
      expect(described_class.filter(VerificationClaim.all)).to be_empty
    end

    it 'excludes a listed article at a different revision' do
      claim(article_id: 1, mw_rev_id: 999)
      rollout_revisions([1, 100])
      expect(described_class.filter(VerificationClaim.all)).to be_empty
    end

    it 'hands back the scope untouched when no list is configured' do
      kept = claim(article_id: 1, mw_rev_id: 100)
      rollout_revisions
      scope = VerificationClaim.all
      expect(described_class.filter(scope).to_sql).to eq(scope.to_sql)
      expect(described_class.filter(scope)).to include(kept)
    end
  end

  describe '.active?' do
    it 'is false with no list configured' do
      rollout_revisions
      expect(described_class).not_to be_active
    end

    it 'is true once the list names a revision' do
      rollout_revisions([1, 100])
      expect(described_class).to be_active
    end
  end

  # Guards the shipped curation output: the file the app reads must parse and
  # must agree with the list the curation scripts generated.
  describe 'the configured list' do
    before { real_rollout_list }

    it 'parses to one (article, revision) pair per rollout article' do
      expect(described_class.pairs.length).to eq(25)
      expect(described_class.pairs).to all(match([be_a(Integer), be_a(Integer)]))
    end

    it 'names each article exactly once' do
      article_ids = described_class.pairs.map(&:first)
      expect(article_ids.uniq.length).to eq(article_ids.length)
    end
  end
end
