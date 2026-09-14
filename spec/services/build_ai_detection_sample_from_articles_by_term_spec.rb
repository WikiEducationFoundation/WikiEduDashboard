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
                                    campaign_slug: 'spring_2021', ground_truth: 'human',
                                    provenance: 'pre_llm_term',
                                    url: 'https://en.wikipedia.org/w/index.php?diff=500&oldid=400')
    expect(unit.metadata).to eq('character_sum' => 5000, 'new_article' => true,
                                'references_count' => 7)
    expect(builder.skipped).to eq([{ reference: 'fall_2026', reason: 'no such campaign' }])
  end

  it 'samples only Wikipedia articles' do
    wikidata = Wiki.find_by(project: 'wikidata') ||
               Wiki.new(language: nil, project: 'wikidata').tap { |w| w.save(validate: false) }
    create(:articles_course, article: create(:article, wiki_id: wikidata.id), course:,
                             character_sum: 9000)

    builder = described_class.new(sample_name: 'terms', terms: %w[spring_2021])

    expect(builder.created.map(&:article_id)).to eq([article.id])
    expect(builder.skipped).to be_empty
  end

  it 'skips articles with no revisions during the course' do
    allow_any_instance_of(CumulativeDiff).to receive(:revision_target).and_return(nil)

    builder = described_class.new(sample_name: 'terms', terms: %w[spring_2021])

    expect(builder.created).to be_empty
    expect(builder.skipped.first[:reason]).to eq('no revisions during the course')
  end

  describe '.term_attributes' do
    it 'labels terms before ChatGPT as human-written and leaves later ones unknown' do
      human = { ground_truth: 'human', provenance: 'pre_llm_term' }
      expect(BuildAiDetectionSample.term_attributes('fall_2019')).to eq(human)
      expect(BuildAiDetectionSample.term_attributes('spring_2022')).to eq(human)
      expect(BuildAiDetectionSample.term_attributes('fall_2022')).to eq({})
      expect(BuildAiDetectionSample.term_attributes('spring_2025')).to eq({})
      expect(BuildAiDetectionSample.term_attributes('not_a_term')).to eq({})
    end
  end
end
