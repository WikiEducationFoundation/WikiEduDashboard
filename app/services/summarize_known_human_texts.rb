# frozen_string_literal: true

require_dependency "#{Rails.root}/app/services/summarize_detector_comparison"
require_dependency "#{Rails.root}/app/services/collect_detector_comparison_scores"

# The known-human texts of the admin detector comparison page, for measuring
# false positives: pre-ChatGPT student contributions to English Wikipedia (the
# cumulative course diffs of the human baseline samples), each with every
# detector's verdict and scores. Other languages are left out so every detector
# is judged on the same texts, and so are redirect pages, whose text is template
# boilerplate rather than writing (an article a student created can be a
# redirect by the end of the course). Grow the set by adding a baseline sample
# to SAMPLES. Cached until a unit or a comparison score changes.
class SummarizeKnownHumanTexts
  SAMPLES = %w[terms_2021_2025_march terms_baseline_extra].freeze
  WIKI_URL = 'https://en.wikipedia.org/%'
  # How GetRevisionPlaintext renders a redirect page.
  REDIRECT_TEXT = 'Redirect to:%'
  UNIT_COLUMNS = %i[id sample_name url word_count text_sha256 article_id campaign_slug].freeze

  attr_reader :result

  def self.units
    AiDetectionSample.where(sample_name: SAMPLES, ground_truth: AiDetectionSample::HUMAN,
                            provenance: AiDetectionSample::PRE_LLM_TERM)
                     .where('url LIKE ?', WIKI_URL)
                     .where.not('plain_text LIKE ?', REDIRECT_TEXT)
  end

  def initialize
    @result = Rails.cache.fetch(cache_key) { build }
  end

  def unit_ids
    @result[:units].map { |unit| unit[:id] }
  end

  private

  def cache_key
    ['detector_comparison/known_human/v2', *SummarizeDetectorComparison.data_version]
  end

  def build
    units = self.class.units.select(UNIT_COLUMNS).includes(:revision_ai_scores).order(:id).to_a
    scores = CollectDetectorComparisonScores.new(units).result
    titles = Article.where(id: units.map(&:article_id).compact).pluck(:id, :title).to_h
    { units: units.map { |unit| unit_row(unit, scores[unit.id], titles[unit.article_id]) },
      samples: SAMPLES, generated_at: Time.zone.now }
  end

  def unit_row(unit, scores, title)
    { id: unit.id, sample: unit.sample_name, url: unit.url, words: unit.word_count,
      term: unit.campaign_slug, title: title&.tr('_', ' '),
      scores: scores.to_h do |score|
        [score.check_type, SummarizeDetectorComparison.score_row(score)]
      end.compact }
  end
end
