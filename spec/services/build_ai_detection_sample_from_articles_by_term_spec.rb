# frozen_string_literal: true

require 'rails_helper'

describe BuildAiDetectionSampleFromArticlesByTerm do
  let(:text) { (['Prose added to the article over the course.'] * 60).join(' ') }
  let(:enwiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:course) { create(:course) }
  let(:campaign) { create(:campaign, slug: 'spring_2021') }
  let(:article) { create(:article, wiki_id: enwiki.id) }
  let(:target) { { rev_id: 500, from_rev: 400, diff_mode: true } }

  before do
    campaign.courses << course
    create(:articles_course, article:, course:, character_sum: 5000, new_article: true,
                             references_count: 7)
    create(:articles_course, article: create(:article, wiki_id: enwiki.id), course:,
                             character_sum: 100)
    allow_any_instance_of(CumulativeDiff).to receive(:revision_target).and_return(target)
    allow(GetRevisionPlaintext).to receive(:new)
      .and_return(instance_double(GetRevisionPlaintext, plain_text: text))
  end

  it 'adds the cumulative course diff of substantial articles, labeled by term' do
    builder = described_class.new(sample_name: 'terms', terms: %w[spring_2021 fall_2026])

    expect(builder.created.count).to eq(1)
    unit = builder.created.first
    expect(unit).to have_attributes(rev_id: 500, from_rev_id: 400, diff_mode: true,
                                    article_id: article.id, course_id: course.id,
                                    campaign_slug: 'spring_2021', ground_truth: 'human_pre_llm',
                                    url: 'https://en.wikipedia.org/w/index.php?diff=500&oldid=400')
    expect(unit.metadata).to eq('character_sum' => 5000, 'new_article' => true,
                                'references_count' => 7)
    expect(builder.skipped).to eq([{ reference: 'fall_2026', reason: 'no such campaign' }])
  end

  it 'skips articles with no revisions during the course' do
    allow_any_instance_of(CumulativeDiff).to receive(:revision_target).and_return(nil)

    builder = described_class.new(sample_name: 'terms', terms: %w[spring_2021])

    expect(builder.created).to be_empty
    expect(builder.skipped.first[:reason]).to eq('no revisions during the course')
  end

  describe '.ground_truth_for_term' do
    it 'treats terms before ChatGPT as human-written and later ones as unknown' do
      expect(BuildAiDetectionSample.ground_truth_for_term('fall_2019')).to eq('human_pre_llm')
      expect(BuildAiDetectionSample.ground_truth_for_term('spring_2022')).to eq('human_pre_llm')
      expect(BuildAiDetectionSample.ground_truth_for_term('fall_2022')).to be_nil
      expect(BuildAiDetectionSample.ground_truth_for_term('spring_2025')).to be_nil
      expect(BuildAiDetectionSample.ground_truth_for_term('not_a_term')).to be_nil
    end
  end
end
