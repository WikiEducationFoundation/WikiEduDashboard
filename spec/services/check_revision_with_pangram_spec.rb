# frozen_string_literal: true

require 'rails_helper'

describe CheckRevisionWithPangram do
  let(:en_wiki) { Wiki.default_wiki }
  let(:course) { create(:course) }
  let(:user) { create(:user) }
  let(:simplified_pangram_response) do
    { 'text' => 'example',
      'avg_ai_likelihood' => 1.0,
      'max_ai_likelihood' => 1.0,
      'prediction' => 'Fully AI-Generated',
      'short_prediction' => 'AI',
      'headline' => 'AI Detected',
      'windows' =>
        [{ 'text' => 'first window',
           'ai_likelihood' => 1.0 },
         { 'text' => 'second window',
           'ai_likelihood' => 1.0 }],
      'window_likelihoods' => [1.0, 1.0],
      'window_indices' => [[0, 2270], [2270, 2550]],
      'fraction_human' => 0.0,
      'fraction_ai' => 1.0,
      'fraction_mixed' => 0.0,
      'metadata' => { 'request_id' => '2e183f04-eea4' },
      'version' => 'adaptive_boundaries',
      'dashboard_link' => 'https://www.pangram.com/history/2e183f04-eea4' }
  end

  context 'when it is the first revision' do
    # https://en.wikipedia.org/w/index.php?title=User:Resekorynta/Evaluate_an_Article&oldid=1315967896
    let!(:sandbox_article) do
      create(:article, namespace: Article::Namespaces::USER,
                       title: 'Resekorynta/Evaluate_an_Article',
                       mw_page_id: 81301594)
    end
    let(:sandbox_creation_revision_id) { 1315967896 }

    it 'fetches the page HTML and checks based on that' do
      expect(AiEditAlert.count).to eq(0)
      expect_any_instance_of(described_class).to receive(:fetch_parent_revision).and_call_original
      expect_any_instance_of(described_class).to receive(:fetch_revision_html).and_call_original
      expect_any_instance_of(described_class).to receive(:generate_plaintext_from_html)
                                             .and_call_original
      expect_any_instance_of(described_class).to receive(:fetch_pangram_inference).and_call_original
      expect_any_instance_of(described_class).to receive(:generate_alert).and_call_original
      expect_any_instance_of(PangramApi).to receive(:inference)
                                        .and_return(simplified_pangram_response)
      VCR.use_cassette 'pangram' do
        described_class.new(en_wiki.id, sandbox_creation_revision_id, user.id, course.id)
      end
      expect(AiEditAlert.count).to eq(1)
      expect(AiEditAlert.last.article_id).to eq(sandbox_article.id)
    end
  end

  context 'when there is a parent revision' do
    let!(:live_article) do
      create(:article, title: '3M_contamination_of_Minnesota_groundwater',
                       mw_page_id: 68907377)
    end
    # https://en.wikipedia.org/w/index.php?title=3M_contamination_of_Minnesota_groundwater&diff=prev&oldid=https://en.wikipedia.org/w/index.php?title=3M_contamination_of_Minnesota_groundwater&diff=prev&oldid=1315795891
    let(:live_article_revision_id) { 1315795891 }

    it 'fetches the diff table and checks based on that' do
      expect(AiEditAlert.count).to eq(0)
      expect_any_instance_of(described_class).to receive(:fetch_parent_revision).and_call_original
      expect_any_instance_of(described_class).to receive(:fetch_diff_table).and_call_original
      expect_any_instance_of(described_class).to receive(:generate_wikitext_from_diff_table)
                                             .and_call_original
      expect_any_instance_of(described_class).to receive(:fetch_parsed_changed_wikitext)
                                             .and_call_original
      expect_any_instance_of(described_class).to receive(:fetch_pangram_inference).and_call_original
      expect_any_instance_of(described_class).to receive(:generate_alert).and_call_original
      expect_any_instance_of(PangramApi).to receive(:inference)
                                        .and_return(simplified_pangram_response)
      VCR.use_cassette 'pangram_2' do
        described_class.new(en_wiki.id, live_article_revision_id, user.id, course.id)
      end
      expect(AiEditAlert.count).to eq(1)
      expect(AiEditAlert.last.article_id).to eq(live_article.id)
    end
  end
end
