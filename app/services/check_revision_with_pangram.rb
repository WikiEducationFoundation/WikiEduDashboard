# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/ai/ai_detector"

class CheckRevisionWithPangram
  # The detector used for production alerting. Changing this key is the cutover.
  DETECTOR_KEY = RevisionAiScore::PANGRAM_V4_KEY

  def initialize(attrs)
    @wiki = Wiki.find attrs['wiki_id']
    @mw_rev_id = attrs['mw_rev_id']
    @user_id = attrs['user_id']
    @course_id = attrs['course_id']
    @rev_datetime = Time.zone.at(attrs['revision_timestamp'])
    @article = Article.find(attrs['article_id'])

    check unless already_checked?
  end

  MIN_PLAIN_TEXT_LENGTH = 500
  def check
    fetch_title_and_plaintext
    # Skip the API call if the plain text is too short.
    return if @plain_text.nil?
    return if @plain_text.length < MIN_PLAIN_TEXT_LENGTH
    return unless fetch_pangram_inference

    parse_pangram_response
    record_successful_check

    generate_alert if ai_likely?
  end

  private

  def fetch_title_and_plaintext
    plaintext_service = GetRevisionPlaintext.new(@mw_rev_id, @wiki)
    @article_title = plaintext_service.article_title
    @plain_text = plaintext_service.plain_text
  end

  # Determines whether the check was already performed for the given revision,
  # based on the existence of a record in the data table with the same revision, wiki, and article,
  # where the details field is not nil.
  # A nil avg_ai_likelihood field may indicate an error occurred when calling the API, so we want
  # to retrieve it again.
  # Only production rows count. Detector comparison samples and the admin AI tools page write
  # rows for revisions production may not have checked yet, and without this filter such a row
  # would suppress the production check and its alert. check_type is deliberately not filtered:
  # a revision already scored with Pangram 3 stays checked and is not re-billed under Pangram 4.
  # NULL is included because check_origin was added in March 2026 and never backfilled; every
  # earlier row with an article_id came from a production check.
  PRODUCTION_ORIGINS = [nil, RevisionAiScore::COURSE_UPDATE_ORIGIN].freeze
  def already_checked?
    RevisionAiScore.where(
      revision_id: @mw_rev_id,
      wiki_id: @wiki.id,
      article_id: @article.id,
      check_origin: PRODUCTION_ORIGINS
    ).where.not(avg_ai_likelihood: nil).exists?
  end

  def detector
    AiDetector.for(DETECTOR_KEY)
  end

  # Returns the raw detector result, or nil when the call failed. Either way the
  # attempt is recorded, as a row with nil avg_ai_likelihood, which already means
  # "check this revision again" to already_checked?. A failure that a retry could
  # clear is re-raised for Sidekiq to retry, bounded in AiDetectionWorker; one that
  # a retry would only re-bill is swallowed here and reported to Sentry instead,
  # since a swallowed failure leaves nothing in the Sidekiq dead set to notice.
  def fetch_pangram_inference
    @pangram_result = detector.client.inference @plain_text
  rescue *AiDetector.recoverable_errors => e
    record_failed_check(e)
    raise unless terminal_failure?(e)

    report_terminal_failure(e)
    nil
  end

  # 4xx statuses a later attempt could clear: the request itself was acceptable,
  # it just arrived at a bad moment. Every other 4xx is a refusal — malformed
  # request, bad key, exhausted credits, oversized text — that will repeat.
  RETRYABLE_STATUSES = [408, 429].freeze

  # A request the API refused and a task the API itself finished in a failed stage
  # will fail the same way however often they are sent.
  def terminal_failure?(error)
    case error
    when PangramApi::RequestError then refused_status?(error.status.to_i)
    when PangramApi::TaskFailed then true
    else false
    end
  end

  def refused_status?(status)
    status.between?(400, 499) && RETRYABLE_STATUSES.exclude?(status)
  end

  # Nothing retries a terminal failure, so this is the only operator-facing signal
  # that checks are failing. Exhausted credits stop production alerting entirely.
  def report_terminal_failure(error)
    Sentry.capture_exception(error, level: 'warning',
                                    extra: { revision_id: @mw_rev_id,
                                             course_id: @course_id,
                                             detector: DETECTOR_KEY })
  end

  # already_checked? guarantees no successful production row exists for this
  # revision, so repeated failures update one row instead of accumulating.
  def record_failed_check(error)
    production_score.update!(
      course_id: @course_id, user_id: @user_id, revision_datetime: @rev_datetime,
      avg_ai_likelihood: nil, max_ai_likelihood: nil,
      details: { 'error' => error.class.name, 'message' => error.message }
    )
  end

  # The one production row for this revision under this detector. A retryable
  # failure records itself here first, so a later success must update that row
  # rather than add a second one alongside it.
  def production_score
    RevisionAiScore.find_or_initialize_by(
      revision_id: @mw_rev_id, wiki_id: @wiki.id, article_id: @article.id,
      check_type: DETECTOR_KEY, check_origin: RevisionAiScore::COURSE_UPDATE_ORIGIN
    )
  end

  def parse_pangram_response
    @parser = detector.parse(@pangram_result)
  end

  def ai_likely?
    # As a start, we'll just look at the most-likely window.
    # In many cases, the max is 1.0, but we'll be a little
    # more conservative.
    @parser.max_ai_likelihood > 0.9
  end

  # Don't generate an alert for old edits.
  MAX_DAYS_FOR_ALERT = 7
  def generate_alert
    return if @rev_datetime < MAX_DAYS_FOR_ALERT.days.ago
    return if alert_already_exists?

    AiEditAlert.generate_alert_from_pangram(revision_id: @mw_rev_id,
                                            user_id: @user_id,
                                            course_id: @course_id,
                                            article_id: @article.id,
                                            article_title: @article_title,
                                            pangram_details: @parser.pangram_details)
  end

  def alert_already_exists?
    AiEditAlert.exists?(revision_id: @mw_rev_id)
  end

  # Imports the scored result into the RevisionAiScores table, over any failure row
  # an earlier attempt at this revision left behind.
  def record_successful_check
    production_score.update!(course_id: @course_id,
                             user_id: @user_id,
                             revision_datetime: @rev_datetime,
                             avg_ai_likelihood: @parser.average_ai_likelihood,
                             max_ai_likelihood: @parser.max_ai_likelihood,
                             details: @parser.clean_result)
  end
end
