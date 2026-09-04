# frozen_string_literal: true

require 'rails_helper'
require_dependency "#{Rails.root}/lib/claim_verification/rollout_list"

describe ClaimVerification::RolloutList do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }

  def claim(article_id:, mw_rev_id:, sentence: 'A fact.')
    VerificationClaim.create!(wiki:, article_id:, mw_rev_id:, sentence:)
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

    it 'drops claims curated out of a listed revision' do
      kept = claim(article_id: 1, mw_rev_id: 100)
      excluded = claim(article_id: 1, mw_rev_id: 100, sentence: 'Another fact.')
      rollout_revisions([1, 100], excluding: [excluded.id])
      expect(described_class.filter(VerificationClaim.all)).to eq([kept])
    end

    # The exclusions outlive the revision allow-list: they still apply to the
    # full pool once that gate is switched off.
    it 'drops curated-out claims even with no revision list configured' do
      kept = claim(article_id: 1, mw_rev_id: 100)
      excluded = claim(article_id: 2, mw_rev_id: 200)
      rollout_revisions(excluding: [excluded.id])
      expect(described_class.filter(VerificationClaim.all)).to eq([kept])
    end
  end

  # A sentence with several citations is pooled once per citation; excluding
  # the claim a student sees for it must take the sentence's other rows too.
  describe '.without_excluded' do
    def claim_with_sentence(sentence, article_id: 1, mw_rev_id: 100)
      VerificationClaim.create!(wiki:, article_id:, mw_rev_id:, sentence:, ref_id: SecureRandom.hex)
    end

    it 'drops every pool row for an excluded claim\'s sentence in that revision' do
      excluded = claim_with_sentence('Otters use tools.')
      claim_with_sentence('Otters use tools.')
      kept = claim_with_sentence('Otters eat urchins.')
      rollout_revisions(excluding: [excluded.id])
      expect(described_class.without_excluded(VerificationClaim.all)).to eq([kept])
    end

    it 'keeps the same sentence pooled from another revision' do
      excluded = claim_with_sentence('Otters use tools.')
      elsewhere = claim_with_sentence('Otters use tools.', mw_rev_id: 200)
      rollout_revisions(excluding: [excluded.id])
      expect(described_class.without_excluded(VerificationClaim.all)).to eq([elsewhere])
    end

    it 'hands back the scope untouched when nothing is excluded' do
      rollout_revisions
      scope = VerificationClaim.all
      expect(described_class.without_excluded(scope).to_sql).to eq(scope.to_sql)
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
      expect(described_class.pairs.length).to eq(22)
      expect(described_class.pairs).to all(match([be_a(Integer), be_a(Integer)]))
    end

    it 'names each article exactly once' do
      article_ids = described_class.pairs.map(&:first)
      expect(article_ids.uniq.length).to eq(article_ids.length)
    end

    # Read straight from the file: the Set the class exposes would hide a claim
    # id accidentally listed twice.
    it 'excludes well-formed claim ids, each listed once' do
      listed = YAML.load_file(described_class::CONFIG_PATH)['excluded_claim_ids']
      expect(listed).to all(be_a(Integer))
      expect(listed.uniq.length).to eq(listed.length)
      expect(described_class.excluded_claim_ids).to eq(listed.to_set)
    end
  end
end
