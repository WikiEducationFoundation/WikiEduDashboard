# frozen_string_literal: true

require_dependency "#{Rails.root}/app/services/export_ai_detection_comparison"
require_dependency "#{Rails.root}/app/services/collect_detector_comparison_scores"

# The data behind the admin detector comparison page: the texts generated on
# the challenge topics, the Agpedia article on each of those topics, the
# student text each topic came from, and each topic's whole article before and
# after the student's term and today, each with every detector's verdict and
# scores. Texts are left out; DescribeDetectorComparisonUnit serves one unit in
# full. Built when PublishDetectorComparison publishes the page's data.
class SummarizeDetectorComparison
  AGPEDIA = 'agpedia'
  # Whole-article revisions of the challenge topics (exemplars/topic_article_versions.py).
  ARTICLE_VERSIONS = %w[pre_llm_revision current_revision].freeze
  # Codex runs that reached the web through ChatGPT workspace apps although web
  # search was off: kept in the samples, left off the page.
  EXCLUDED_CONDITIONS = %w[assignment_apps_web].freeze
  RETIRED_SAMPLES = '%_retired'
  # The Dashboard's alert rule: any Pangram window scoring above this.
  ALERT_THRESHOLD = 0.9
  # Verdict labels that clear a text. Any other label counts as a detection: AI, Pangram's
  # Mixed, and Open Pangram's AI-edited levels.
  HUMAN_LABELS = %w[Human Original].freeze
  UNIT_COLUMNS = %i[id sample_name ground_truth provenance url word_count text_sha256 factors
                    metadata].freeze

  attr_reader :result

  # Texts in samples still in use, of one provenance.
  def self.current_units(provenance)
    AiDetectionSample.where(provenance:).where.not('sample_name LIKE ?', RETIRED_SAMPLES)
  end

  def self.flagged?(label)
    label.present? && HUMAN_LABELS.exclude?(label)
  end

  # Verdict and scores of one stored row, or nil for a failed call.
  def self.score_row(score)
    return if score.avg_ai_likelihood.nil?

    summary = ExportAiDetectionComparison.summary_for(score)
    row = { label: summary['label'], flagged: flagged?(summary['label']),
            max: summary['max_score'], mean: summary['mean_window_score'],
            document: summary['document_score'], windows: summary['window_count'] }
    return row unless score.check_type.start_with?('Pangram')

    row.merge(alert: summary['max_score'].to_f > ALERT_THRESHOLD)
  end

  def initialize
    @result = build
  end

  def unit_ids
    @result[:units].map { |unit| unit[:id] }
  end

  private

  def build
    generated = load_units(self.class.current_units(AiDetectionSample::SYNTHETIC))
                .reject { |unit| EXCLUDED_CONDITIONS.include?(unit.metadata['condition']) }
    units = generated + agpedia_articles(generated) + topic_articles(generated) +
            paired_texts(generated)
    @scores = CollectDetectorComparisonScores.new(units).result
    { units: units.map { |unit| unit_row(unit) }, prompts: prompts(generated),
      generated_at: Time.zone.now }
  end

  # The prompts each strategy sent, as stored with one of its texts, with the topic's name
  # replaced by {topic}. Strategies whose texts have no stored prompts are left out.
  def prompts(generated)
    generated.group_by { |unit| unit.metadata['condition'] }.filter_map do |condition, units|
      unit = units.find { |candidate| candidate.metadata['prompts'].present? }
      next unless condition && unit

      [condition, with_topic_placeholder(unit.metadata['prompts'], unit.factors['topic'].to_s)]
    end.to_h
  end

  # Whole Agpedia articles on the generated texts' topics; leads and other articles are left out.
  def agpedia_articles(generated)
    topics = generated.to_set { |unit| unit.factors['topic'] }
    load_units(self.class.current_units(AGPEDIA)).select do |unit|
      unit.factors['excerpt'] == 'full' && topics.include?(unit.factors['topic'])
    end
  end

  # Each topic's article before and after the student's term and today.
  def topic_articles(generated)
    topics = generated.to_set { |unit| unit.factors['topic'] }
    load_units(self.class.current_units(ARTICLE_VERSIONS))
      .select { |unit| topics.include?(unit.factors['topic']) }
  end

  # The student texts the topics were taken from.
  def paired_texts(generated)
    ids = generated.filter_map { |unit| unit.metadata['paired_unit_id'].presence&.to_i }
    load_units(AiDetectionSample.where(id: ids.uniq))
  end

  def with_topic_placeholder(turns, topic)
    topic.empty? ? turns : turns.map { |turn| turn.gsub(topic, '{topic}') }
  end

  def load_units(scope)
    scope.select(UNIT_COLUMNS).includes(:revision_ai_scores).to_a
  end

  def unit_row(unit)
    { id: unit.id, sample: unit.sample_name, ground_truth: unit.ground_truth,
      provenance: unit.provenance, words: unit.word_count, url: unit.url,
      factors: unit.factors, condition: unit.metadata['condition'],
      paired_unit_id: unit.metadata['paired_unit_id'].presence&.to_i,
      scores: scores(unit) }
  end

  def scores(unit)
    @scores[unit.id].to_h { |score| [score.check_type, self.class.score_row(score)] }.compact
  end
end
