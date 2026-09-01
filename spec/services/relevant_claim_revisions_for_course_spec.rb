# frozen_string_literal: true

require 'rails_helper'

describe RelevantClaimRevisionsForCourse do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:student_course) { a_course(subject: 'Biology') }

  # The course factory's default slug is fixed, so give each one a unique slug.
  def a_course(subject: nil)
    create(:course, slug: "School/#{SecureRandom.hex(4)}", subject:)
  end

  def article(title)
    create(:article, wiki:, title:, namespace: Article::Namespaces::MAINSPACE)
  end

  def pool_claim(article:, rev:, source_course:, subject: nil, sentence: 'A fact.',
                 mw_rev_timestamp: nil)
    alert = create(:ai_edit_alert, course: source_course, article:, revision_id: rev,
                                   details: { article_title: article.title })
    VerificationClaim.create!(wiki:, article:, article_title: article.title, mw_rev_id: rev,
                              sentence:, subject:, source_course:, alert:, mw_rev_timestamp:)
  end

  it 'returns one tile per (article, revision) with a claim count' do
    otter = article('Otter')
    pool_claim(article: otter, rev: 10, source_course: a_course, sentence: 'One.')
    pool_claim(article: otter, rev: 10, source_course: a_course, sentence: 'Two.')
    tiles = described_class.new(student_course).tiles
    expect(tiles.size).to eq(1)
    expect([tiles.first.article, tiles.first.mw_rev_id, tiles.first.claim_count])
      .to eq([otter, 10, 2])
  end

  it 'carries the flagged revision timestamp on each tile' do
    ts = Time.utc(2025, 12, 14, 4, 53, 46)
    otter = article('Otter')
    pool_claim(article: otter, rev: 10, source_course: a_course, mw_rev_timestamp: ts)
    expect(described_class.new(student_course).tiles.first.mw_rev_timestamp).to eq(ts)
  end

  it 'prioritizes claims from courses sharing a subject tag' do
    tagged_source = a_course
    create(:tag, course: tagged_source, tag: 'biology', key: 'topics-biology')
    create(:tag, course: student_course, tag: 'biology', key: 'topics-biology')
    related = article('Cell')
    pool_claim(article: related, rev: 1, source_course: tagged_source)
    pool_claim(article: article('Rock'), rev: 2, source_course: a_course)
    tiles = described_class.new(student_course, limit: 1).tiles
    expect(tiles.map(&:article)).to eq([related])
  end

  it 'falls back to the general pool when nothing matches by subject' do
    quartz = article('Quartz')
    pool_claim(article: quartz, rev: 3, source_course: a_course)
    expect(described_class.new(student_course).tiles.map(&:article)).to eq([quartz])
  end

  it 'ignores claims not harvested from an alert' do
    VerificationClaim.create!(wiki:, article: article('Legacy'), mw_rev_id: 5,
                              sentence: 'Legacy.', alert: nil)
    expect(described_class.new(student_course).tiles).to be_empty
  end

  # The temporary rollout gate: config/claim_verification_rollout.yml.
  context 'when a rollout list is configured' do
    it 'offers only listed revisions' do
      approved = article('Otter')
      pool_claim(article: approved, rev: 10, source_course: a_course)
      pool_claim(article: article('Rock'), rev: 20, source_course: a_course)
      rollout_revisions([approved.id, 10])
      expect(described_class.new(student_course).tiles.map(&:article)).to eq([approved])
    end

    it 'keeps subject-tag priority within the listed revisions' do
      tagged_source = a_course
      create(:tag, course: tagged_source, tag: 'biology', key: 'topics-biology')
      create(:tag, course: student_course, tag: 'biology', key: 'topics-biology')
      related = article('Cell')
      general = article('Quartz')
      pool_claim(article: related, rev: 1, source_course: tagged_source)
      pool_claim(article: general, rev: 2, source_course: a_course)
      rollout_revisions([related.id, 1], [general.id, 2])
      expect(described_class.new(student_course, limit: 1).tiles.map(&:article)).to eq([related])
    end

    # Prioritization orders the approved set; it can never reach past it.
    it 'does not fall back to unlisted revisions when the listed set is thin' do
      approved = article('Otter')
      pool_claim(article: approved, rev: 10, source_course: a_course)
      3.times do |i|
        pool_claim(article: article("Other#{i}"), rev: 30 + i, source_course: a_course)
      end
      rollout_revisions([approved.id, 10])
      expect(described_class.new(student_course).tiles.map(&:article)).to eq([approved])
    end

    it 'offers nothing when the pool and the list do not overlap' do
      pool_claim(article: article('Otter'), rev: 10, source_course: a_course)
      rollout_revisions([999_999, 10])
      expect(described_class.new(student_course).tiles).to be_empty
    end
  end

  # Claims curated out individually (excluded_claim_ids in the rollout config).
  context 'when claims are curated out of the rollout' do
    it 'leaves them out of the tile claim count' do
      otter = article('Otter')
      pool_claim(article: otter, rev: 10, source_course: a_course, sentence: 'One.')
      excluded = pool_claim(article: otter, rev: 10, source_course: a_course, sentence: 'Two.')
      rollout_revisions([otter.id, 10], excluding: [excluded.id])
      expect(described_class.new(student_course).tiles.map(&:claim_count)).to eq([1])
    end

    it 'offers no tile for a revision with every claim curated out' do
      otter = article('Otter')
      excluded = pool_claim(article: otter, rev: 10, source_course: a_course)
      rollout_revisions(excluding: [excluded.id])
      expect(described_class.new(student_course).tiles).to be_empty
    end
  end
end
