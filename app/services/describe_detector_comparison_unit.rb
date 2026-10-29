# frozen_string_literal: true

require_dependency "#{Rails.root}/app/services/summarize_detector_comparison"
require_dependency "#{Rails.root}/app/services/collect_detector_comparison_scores"
require_dependency "#{Rails.root}/lib/ai/pangram_window_segments"

# One unit of the detector comparison page in full: the text the
# detectors scored, the text as written, the prompts that produced it, its
# factors and metadata, and each detector's result (including results stored on
# an identical copy of the text), with Pangram's windows mapped onto the text.
# Only units the page lists, in either dataset, can be described; the datasets
# are the results of SummarizeDetectorComparison and SummarizeKnownHumanTexts.
class DescribeDetectorComparisonUnit
  attr_reader :result

  def initialize(id, topics:, known_human:)
    @topics = topics
    @datasets = { 'topics' => topics, 'known_human' => known_human }
                .select { |_, dataset| dataset[:units].any? { |unit| unit[:id] == id.to_i } }.keys
    raise ActiveRecord::RecordNotFound if @datasets.empty?

    @unit = AiDetectionSample.find(id)
    @scores = CollectDetectorComparisonScores.new([@unit]).result[@unit.id].sort_by(&:check_type)
    @result = describe
  end

  private

  def describe
    { id: @unit.id, sample: @unit.sample_name, datasets: @datasets,
      ground_truth: @unit.ground_truth, provenance: @unit.provenance, url: @unit.url,
      words: @unit.word_count,
      notes: @unit.notes, factors: @unit.factors,
      metadata: @unit.metadata.except('prompts'), prompts: @unit.metadata['prompts'],
      pair_topic:, topic_page:, prior_article_url:, text: @unit.plain_text,
      source_text: @unit.source_text, source_format: @unit.source_format,
      scores: @scores.map { |score| score_detail(score) }, highlight: }
  end

  def score_detail(score)
    detail = { check_type: score.check_type, scored_at: score.created_at,
               imported: score.details.key?('summary') }
    return detail.merge(error: score.details['message']) if score.avg_ai_likelihood.nil?

    summary = ExportAiDetectionComparison.summary_for(score)
    detail.merge(summary:, flagged: SummarizeDetectorComparison.flagged?(summary['label']),
                 windows: pangram_windows(score), blocks: originality_blocks(score))
  end

  def pangram_windows(score)
    return [] unless score.check_type.start_with?('Pangram')

    Array(score.details['windows']).map do |window|
      { label: window['label'], score: window['ai_assistance_score'],
        confidence: window['confidence'], words: window['word_count'],
        humanized: window['is_humanized'], humanizer_score: window['humanizer_score'] }
    end
  end

  def originality_blocks(score)
    blocks = score.details.dig('results', 'ai', 'blocks')
    return [] unless blocks.is_a?(Array)

    blocks.map do |block|
      { ai: block.dig('result', 'fake'), status: block.dig('result', 'status') }
    end
  end

  # The text cut at the windows of the newest Pangram model that scored it.
  def highlight
    score = @scores.reverse.find do |candidate|
      candidate.check_type.start_with?('Pangram') && candidate.details['windows'].present?
    end
    return unless score

    segments = PangramWindowSegments.new(@unit.plain_text, score.details['windows'])
    return if segments.parts.empty?

    { check_type: score.check_type, approximate: segments.approximate?, parts: segments.parts }
  end

  # For a student text, the topic of the generated texts paired with it.
  def pair_topic
    @topics[:units].find { |unit| unit[:paired_unit_id] == @unit.id }&.dig(:factors, 'topic')
  end

  # The topic whose page lists this text: its own or its pair's, when texts were generated on it.
  def topic_page
    topic = @unit.factors['topic'] || pair_topic
    generated = @topics[:units].any? do |unit|
      unit[:provenance] == AiDetectionSample::SYNTHETIC && unit[:factors]['topic'] == topic
    end
    topic if topic && generated
  end

  # The assignment flow's outline prompt quotes the article as it stood before
  # the student's term; the prompts store a placeholder and the page links here.
  def prior_article_url
    rev_id = @unit.metadata['prior_rev_id'].presence
    return unless rev_id

    host = URI.parse(@unit.metadata['paired_url'].to_s).host || 'en.wikipedia.org'
    "https://#{host}/w/index.php?oldid=#{rev_id.to_i}"
  end
end
