# frozen_string_literal: true

require 'rails_helper'

describe BuildAiDetectionSampleFromRecentScores do
  let(:text) { (['Prose added by the student in one edit.'] * 60).join(' ') }
  let(:enwiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:course) { create(:course) }
  let(:campaign) { create(:campaign, slug: 'fall_2026') }
  let(:article) { create(:article, namespace: 2, wiki_id: enwiki.id) }

  def production_score(rev_id, max, created_at: 1.day.ago, origin: 'course_update')
    RevisionAiScore.create!(revision_id: rev_id, wiki_id: enwiki.id, article_id: article.id,
                            course_id: course.id, max_ai_likelihood: max, avg_ai_likelihood: max,
                            check_type: 'Pangram 3', check_origin: origin, created_at:)
  end

  before do
    campaign.courses << course
    allow(GetRevisionPlaintext).to receive(:new)
      .and_return(instance_double(GetRevisionPlaintext, plain_text: text))
  end

  it 'samples production-scored edits from each score band with their context' do
    production_score(101, 0.1)
    production_score(102, 0.7)
    production_score(103, 0.95)
    production_score(104, 0.99, origin: 'ai_tool')
    production_score(105, 0.99, created_at: 60.days.ago)

    builder = described_class.new(sample_name: 'recent', per_band: 5)

    expect(builder.created.map(&:rev_id)).to contain_exactly(101, 102, 103)
    expect(GetRevisionPlaintext).to have_received(:new)
      .with(101, enwiki, diff_mode: true, from_rev: nil)
    unit = builder.created.find { |u| u.rev_id == 103 }
    expect(unit).to have_attributes(article_id: article.id, course_id: course.id,
                                    campaign_slug: 'fall_2026', namespace: 2, diff_mode: true,
                                    url: 'https://en.wikipedia.org/w/index.php?diff=103')
    expect(unit.metadata).to include('band' => 'high', 'source_max_ai_likelihood' => 0.95,
                                     'source_check_type' => 'Pangram 3')
  end

  it 'limits each band to per_band units' do
    production_score(201, 0.91)
    production_score(202, 0.92)
    production_score(203, 0.93)

    builder = described_class.new(sample_name: 'recent', per_band: 2)

    expect(builder.created.count).to eq(2)
  end
end
