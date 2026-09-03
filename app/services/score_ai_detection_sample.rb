# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/ai/ai_detector"

# Sends every unit of a named AiDetectionSample to the given detectors and
# stores each result as a RevisionAiScore with check_origin
# 'detector_comparison'. Resumable: units a detector has already scored are
# skipped, and a unit whose call failed (nil avg_ai_likelihood) is retried on
# the next run, updating the failed row rather than adding another.
#
# Some vendors meter credits, so run with dry_run: true first: the report then
# lists pending units, words and estimated credits per detector, plus the
# current balance of every vendor that reports one, without calling any
# detector. Vendor specifics (minimum input, billing, balance, error classes)
# come from the AiDetector registry, so a new detector needs nothing here.
class ScoreAiDetectionSample
  attr_reader :report

  def initialize(sample_name:, detectors:, dry_run: false, verbose: false, limit: nil)
    @units = AiDetectionSample.named(sample_name).order(:id)
    @units = @units.limit(limit) if limit
    @detectors = detectors.map { |key| AiDetector.for(key) }
    @verbose = verbose
    @report = {}
    dry_run ? plan : perform
  end

  private

  def pending_units(detector)
    scored_ids = RevisionAiScore.where(sample_id: @units.map(&:id), check_type: detector.key)
                                .where.not(avg_ai_likelihood: nil).pluck(:sample_id)
    @units.reject { |unit| scored_ids.include?(unit.id) || too_short?(detector, unit) }
  end

  # Some vendors refuse short texts.
  def too_short?(detector, unit)
    detector.min_words.present? && unit.word_count < detector.min_words
  end

  def plan
    @detectors.each do |detector|
      units = pending_units(detector)
      word_counts = units.map(&:word_count)
      @report[detector.key] = { pending_units: units.count,
                                pending_words: word_counts.sum,
                                estimated_credits: detector.estimated_credits(word_counts) }
    end
    @report.merge!(AiDetector.credit_balances(@detectors))
    log @report
  end

  def perform
    @detectors.each do |detector|
      stats = @report[detector.key] = { scored: 0, failed: 0 }
      pending_units(detector).each { |unit| score_unit(detector, unit, stats) }
    end
  end

  def score_unit(detector, unit, stats)
    parser = detector.score(unit.plain_text)
    save_score(detector, unit, avg: parser.average_ai_likelihood, max: parser.max_ai_likelihood,
                               details: parser.clean_result)
    stats[:scored] += 1
    log "#{detector.key}: unit #{unit.id} max #{parser.max_ai_likelihood.round(4)}"
  rescue *AiDetector.recoverable_errors => e
    save_score(detector, unit, avg: nil, max: nil,
                               details: { 'error' => e.class.name, 'message' => e.message })
    stats[:failed] += 1
    log "#{detector.key}: unit #{unit.id} failed: #{e.message}"
  end

  def save_score(detector, unit, avg:, max:, details:)
    score = RevisionAiScore.find_or_initialize_by(sample_id: unit.id, check_type: detector.key)
    score.update!(revision_id: unit.rev_id, wiki_id: unit.wiki_id, url: unit.url,
                  article_id: unit.article_id, course_id: unit.course_id,
                  avg_ai_likelihood: avg, max_ai_likelihood: max, details:,
                  check_origin: RevisionAiScore::DETECTOR_COMPARISON_ORIGIN)
  end

  def log(message)
    puts message if @verbose # rubocop:disable Rails/Output
  end
end
