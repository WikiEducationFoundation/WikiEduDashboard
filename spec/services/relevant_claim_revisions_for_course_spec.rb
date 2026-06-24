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
end
