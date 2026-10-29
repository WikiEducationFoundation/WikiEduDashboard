# frozen_string_literal: true

require "#{Rails.root}/lib/ai/detector_summary"

# A generated text scored by Pangram 4, Originality and an imported offline
# detector, the human baseline text it is paired with, and units the
# detector comparison page leaves out.
RSpec.shared_context 'detector comparison data' do
  let(:human_text) { (['A student wrote this paragraph about glacial streams.'] * 50).join(' ') }
  let(:generated_text) do
    "#{(['Glacial streams are channels fed by melting ice.'] * 30).join(' ')}\n\n" \
      "#{(['Their temperature stays near freezing all year.'] * 30).join(' ')}"
  end
  let(:split) { generated_text.index("\n\n") + 2 }
  let!(:human) do
    AiDetectionSample.create!(sample_name: 'terms_2021_2025_march', plain_text: human_text,
                              ground_truth: 'human', provenance: 'pre_llm_term',
                              url: 'https://en.wikipedia.org/w/index.php?diff=20&oldid=10')
  end
  let!(:generated) do
    AiDetectionSample.create!(
      sample_name: 'generated_stratified_2026_10', plain_text: generated_text,
      ground_truth: 'ai', provenance: 'synthetic',
      factors: { 'model' => 'gpt-6-astra', 'topic' => 'Glacial stream', 'prompt' => 'assignment' },
      metadata: { 'condition' => 'assignment', 'paired_unit_id' => human.id.to_s,
                  'prior_rev_id' => '1011811699',
                  'paired_url' => 'https://en.wikipedia.org/w/index.php?diff=20&oldid=10',
                  'prompts' => ['Assigned article: Glacial stream',
                                "Current article:\n\n{prior_article}",
                                'Start drafting your contributions'] },
      source_text: "Sure! Here is the draft.\n\n#{generated_text}\n\n== References ==",
      source_format: 'model_reply'
    )
  end
  let!(:retired) do
    AiDetectionSample.create!(sample_name: 'generated_stratified_2026_10_retired',
                              plain_text: "Retired #{generated_text}", ground_truth: 'ai',
                              provenance: 'synthetic')
  end
  let!(:agpedia_article) do
    AiDetectionSample.create!(sample_name: 'agpedia_topics_2026_10',
                              plain_text: "Agpedia #{generated_text}",
                              ground_truth: 'ai', provenance: 'agpedia',
                              factors: { 'topic' => 'Glacial stream', 'excerpt' => 'full',
                                         'model' => 'claude-sonnet-5-5' })
  end
  let!(:agpedia_lead) do
    AiDetectionSample.create!(sample_name: 'agpedia_topics_leads_2026_10',
                              plain_text: "Lead #{generated_text}",
                              ground_truth: 'ai', provenance: 'agpedia',
                              factors: { 'topic' => 'Glacial stream', 'excerpt' => 'lead' })
  end
  let!(:other_agpedia) do
    AiDetectionSample.create!(sample_name: 'agpedia_2026_10', plain_text: "Other #{generated_text}",
                              ground_truth: 'ai', provenance: 'agpedia',
                              factors: { 'topic' => 'ai-agent', 'excerpt' => 'full' })
  end
  let!(:article_after_term) do
    AiDetectionSample.create!(sample_name: 'topic_articles_2026_10',
                              plain_text: "Whole article #{human_text}",
                              ground_truth: 'human', provenance: 'pre_llm_revision',
                              factors: { 'topic' => 'Glacial stream', 'version' => 'after_term' })
  end
  let!(:other_article) do
    AiDetectionSample.create!(sample_name: 'topic_articles_2026_10',
                              plain_text: "Another article #{human_text}",
                              provenance: 'current_revision',
                              factors: { 'topic' => 'Rooibos', 'version' => 'today' })
  end
  let!(:repeated_baseline) do
    AiDetectionSample.create!(sample_name: 'originality_2026_09', plain_text: human_text,
                              ground_truth: 'human', provenance: 'pre_llm_term')
  end

  def pangram_details(windows, label)
    { 'version' => '4.0', 'prediction_short' => label, 'fraction_ai' => 0.5,
      'fraction_ai_assisted' => 0.0, 'fraction_human' => 0.5, 'windows' => windows,
      'dashboard_link' => 'https://www.pangram.com/history/abc' }
  end

  def pangram_window(score, start_index, end_index)
    { 'label' => score > 0.5 ? 'AI-Generated' : 'Human Written', 'ai_assistance_score' => score,
      'confidence' => 'High', 'start_index' => start_index, 'end_index' => end_index,
      'word_count' => 240, 'is_humanized' => false, 'humanizer_score' => 0.01 }
  end

  def originality_ai_result
    { 'aiModel' => 'allowance-40%', 'classification' => { 'AI' => 1, 'Original' => 0 },
      'confidence' => { 'AI' => 0.99, 'Original' => 0.01 },
      'blocks' => [{ 'result' => { 'fake' => 1.0, 'real' => 0.0, 'status' => 'success' } }] }
  end

  before do
    generated.revision_ai_scores.create!(
      check_type: 'Pangram 4', check_origin: 'detector_comparison',
      avg_ai_likelihood: 0.6, max_ai_likelihood: 0.95,
      details: pangram_details([pangram_window(0.95, 0, split),
                                pangram_window(0.25, split, generated_text.length)], 'Mixed')
    )
    generated.revision_ai_scores.create!(
      check_type: 'Originality AI Allowance 40', check_origin: 'detector_comparison',
      avg_ai_likelihood: 0.99, max_ai_likelihood: 1.0,
      details: { 'results' => { 'properties' => { 'publicLink' => 'https://originality.ai/r/1' },
                                'ai' => originality_ai_result } }
    )
    generated.revision_ai_scores.create!(
      check_type: 'Originality AI Allowance 15', check_origin: 'detector_comparison',
      details: { 'error' => 'OriginalityApi::RequestError', 'message' => 'HTTP 402' }
    )
    generated.revision_ai_scores.create!(
      check_type: 'Open Pangram EditLens Llama', check_origin: 'detector_comparison',
      avg_ai_likelihood: 0.4, max_ai_likelihood: 0.5,
      details: { 'summary' => DetectorSummary::KEYS.index_with(nil)
                                .merge('check_type' => 'Open Pangram EditLens Llama',
                                       'vendor' => 'open_pangram', 'label' => 'AI-edited 1',
                                       'document_score' => 0.4, 'max_score' => 0.5),
                 'imported_from' => 'all_units_llama.csv' }
    )
    [human, repeated_baseline].each do |unit|
      unit.revision_ai_scores.create!(
        check_type: 'Pangram 4', check_origin: 'detector_comparison',
        avg_ai_likelihood: 0.0, max_ai_likelihood: 0.001,
        details: pangram_details([pangram_window(0.001, 0, human_text.length)], 'Human')
      )
    end
  end
end

# The same data, with PublishDetectorComparison writing into a directory of the
# spec's own, so a spec never touches a development publication. Specs publish
# when they need to.
RSpec.shared_context 'published detector comparison data' do
  include_context 'detector comparison data'

  let(:snapshot_root) { Pathname(Dir.mktmpdir('detector_comparison')) }

  before { allow(PublishDetectorComparison).to receive(:root).and_return(snapshot_root) }

  after { FileUtils.rm_rf(snapshot_root) }
end
