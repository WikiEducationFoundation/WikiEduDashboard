# frozen_string_literal: true

require_dependency "#{Rails.root}/app/services/summarize_detector_comparison"
require_dependency "#{Rails.root}/lib/ai/pangram_window_segments"

# One unit of the admin detector comparison page in full: the text the
# detectors scored, the text as written, the prompts that produced it, its
# factors and metadata, and each detector's result, with Pangram's windows
# mapped onto the text. Only units the page lists (known-AI samples and the
# human baseline) can be described.
class DescribeDetectorComparisonUnit
  attr_reader :result

  def initialize(id)
    @unit = SummarizeDetectorComparison.page_units
                                       .or(SummarizeDetectorComparison.baseline_units)
                                       .find(id)
    @scores = @unit.revision_ai_scores.sort_by(&:check_type)
    @result = describe
  end

  private

  def describe
    { id: @unit.id, sample: @unit.sample_name, ground_truth: @unit.ground_truth,
      provenance: @unit.provenance, url: @unit.url, words: @unit.word_count,
      notes: @unit.notes, factors: @unit.factors,
      metadata: @unit.metadata.except('prompts'), prompts: @unit.metadata['prompts'],
      prior_article_url:, text: @unit.plain_text,
      source_text: @unit.source_text, source_format: @unit.source_format,
      scores: @scores.map { |score| score_detail(score) }, highlight: }
  end

  def score_detail(score)
    detail = { check_type: score.check_type, scored_at: score.created_at,
               imported: score.details.key?('summary') }
    return detail.merge(error: score.details['message']) if score.avg_ai_likelihood.nil?

    detail.merge(summary: ExportAiDetectionComparison.summary_for(score),
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

  # The assignment flow's outline prompt quotes the article as it stood before
  # the student's term; the prompts store a placeholder and the page links here.
  def prior_article_url
    rev_id = @unit.metadata['prior_rev_id'].presence
    return unless rev_id

    host = URI.parse(@unit.metadata['paired_url'].to_s).host || 'en.wikipedia.org'
    "https://#{host}/w/index.php?oldid=#{rev_id.to_i}"
  end
end
