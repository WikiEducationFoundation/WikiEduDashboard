# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/ai/ai_detector"
require_dependency "#{Rails.root}/app/services/score_ai_detection_sample"
require_dependency "#{Rails.root}/app/services/summarize_detector_comparison"
require_dependency "#{Rails.root}/app/services/summarize_known_human_texts"

# Scores the core texts of the detector comparison with the current detectors
# (AiDetector.keys) in the background, so a new detector or model version can be
# compared with everything the earlier ones scored. The core texts are the units
# behind the comparison page: the known-human texts and the topics dataset. Each
# distinct text is scored once; results on identical copies count for every unit
# that holds the text (CollectDetectorComparisonScores).
#
# In a production console:
#   ScoreDetectorComparisonCore.plan    # pending texts and estimated credits per detector
#   ScoreDetectorComparisonCore.start(max_originality_credits: 40_000)  # queue the run
#   ScoreDetectorComparisonCore.status  # progress, or why the run stopped
#   ScoreDetectorComparisonCore.stop    # stop after the current chunk
#
# The run is one ScoreDetectorComparisonCoreWorker job at a time on the
# report_csv queue, each scoring CHUNK_SIZE texts and queuing the next. Each run
# has an id that its jobs carry; a job whose run is no longer the current one
# exits without saving, and a stop requested mid-chunk takes effect when the
# chunk ends. Detectors run one after another in the order given (registry order
# by default, which puts Originality 5.0 Max last). A text whose call fails is
# not sent again during the same run. The run stops, recording why in its
# status, when:
# - a pinned detector's vendor answers with another model version;
# - FAILURE_LIMIT calls in a row fail, or MAX_FAILURES calls of one detector fail;
# - Originality credits spent since this start exceed max_originality_credits;
# - after BILLING_CHECK_UNITS texts of an Originality detector, it has spent more
#   than BILLING_TOLERANCE times its estimate. Originality lists 5.0 Max at ten
#   times 5.0's price, although the API charged the same in a first probe.
# Starting again continues with the texts not yet scored, retrying failed ones.
# start refuses while a run is in progress; force: true replaces a run whose job
# was lost (its status stays 'running' with nothing queued). To analyze the
# results locally, export them with ExportDetectorComparisonScores.
class ScoreDetectorComparisonCore
  SETTING_KEY = 'detector_comparison_core_run'
  CHUNK_SIZE = 10
  FAILURE_LIMIT = 10
  MAX_FAILURES = 50
  LIVE_STATES = %w[running stopping].freeze
  BILLING_CHECK_UNITS = 10
  BILLING_TOLERANCE = 2
  # Columns needed to tell which texts are pending; the chunk being scored loads in full.
  PENDING_COLUMNS = %i[id word_count].freeze

  # The core texts, one unit per distinct text.
  def self.units
    all = SummarizeKnownHumanTexts.units.select(:id, :text_sha256).to_a +
          SummarizeDetectorComparison.units
    all.uniq(&:id).group_by(&:text_sha256).values.map { |copies| copies.min_by(&:id) }
       .sort_by(&:id)
  end

  def self.plan(detectors: AiDetector.keys)
    ids = units.map(&:id)
    ScoreAiDetectionSample.new(units: AiDetectionSample.where(id: ids).order(:id).to_a,
                               detectors:, dry_run: true).report
  end

  def self.start(max_originality_credits:, detectors: AiDetector.keys, force: false)
    check_startable(detectors, force)
    id = SecureRandom.hex(6)
    save_run('id' => id, 'state' => 'running', 'detectors' => detectors,
             'unit_ids' => units.map(&:id), 'max_originality_credits' => max_originality_credits,
             'start_balance' => (originality_balance if detectors.any? { |key| metered?(key) }),
             'started_at' => Time.zone.now.iso8601, 'scored' => 0, 'failed' => 0,
             'failures_in_a_row' => 0, 'phases' => {}, 'message' => nil)
    return status if ScoreDetectorComparisonCoreWorker.perform_async(id)

    save_run(run.merge('state' => 'stopped', 'message' => 'The first job was not queued'))
    raise 'The first job was not queued; a stale Sidekiq lock may remain'
  end

  def self.check_startable(detectors, force)
    unselectable = detectors.reject { |key| AiDetector.selectable?(key) }
    raise ArgumentError, "not offered for comparison scoring: #{unselectable}" if unselectable.any?
    return if force || LIVE_STATES.exclude?(run['state'])

    raise ArgumentError, "a run is #{run['state']}; stop it first, or pass force: true " \
                         'if its job was lost'
  end

  def self.metered?(key)
    AiDetector.for(key).vendor.balance_reader.present?
  end

  def self.stop
    save_run(run.merge('state' => 'stopping')) if run['state'] == 'running'
    status
  end

  # The run's progress and settings, without its list of unit ids.
  def self.status
    run.except('unit_ids')
  end

  def self.run
    Setting.find_by(key: SETTING_KEY)&.value || {}
  end

  def self.save_run(value)
    Setting.find_or_create_by(key: SETTING_KEY)
           .update!(value: value.merge('updated_at' => Time.zone.now.iso8601))
  end

  def self.originality_balance
    OriginalityApi.credit_balance
  end

  # Scores one chunk of the run with this id; the worker calls this. Returns true
  # when another chunk should be queued.
  def self.step(id)
    ScoreDetectorComparisonChunk.new(run, id).step
  end
end
