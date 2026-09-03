# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/ai/ai_detector"

# Sends every unit of a named AiDetectionSample to the given detectors and
# stores each result as a RevisionAiScore with check_origin
# 'detector_comparison'. Resumable: units a detector has already scored are
# skipped, and a unit whose call failed (nil avg_ai_likelihood) is retried on
# the next run, updating the failed row rather than adding another.
#
# Originality.ai credits are limited, so run with dry_run: true first: the
# report then lists pending units, words and estimated credits per detector,
# plus the current credit balance, without calling any detector.
class ScoreAiDetectionSample
  attr_reader :report

  # Originality bills about one credit per 100 words per check, and an
  # allowance scan appears to bill as an AI check plus an allowance check.
  ORIGINALITY_WORDS_PER_CREDIT = 100
  API_ERRORS = [PangramApi::Error, OriginalityApi::Error, Faraday::Error, JSON::ParserError].freeze

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

  # Originality refuses short texts; Pangram has no such floor.
  def too_short?(detector, unit)
    !detector.pangram? && unit.word_count < OriginalityApi::MIN_WORDS
  end

  def plan
    @detectors.each do |detector|
      units = pending_units(detector)
      @report[detector.key] = { pending_units: units.count,
                                pending_words: units.sum(&:word_count),
                                estimated_credits: estimated_credits(detector, units) }
    end
    @report['originality_credit_balance'] = credit_balance unless @detectors.all?(&:pangram?)
    log @report
  end

  def estimated_credits(detector, units)
    return if detector.pangram?

    per_check = units.sum { |unit| unit.word_count.fdiv(ORIGINALITY_WORDS_PER_CREDIT).ceil }
    detector.client.expected_model.start_with?('allowance') ? per_check * 2 : per_check
  end

  def credit_balance
    OriginalityApi.credit_balance
  rescue OriginalityApi::Error, Faraday::Error => e
    e.message
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
  rescue *API_ERRORS => e
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
