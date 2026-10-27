# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/ai/ai_detector"

# Follows up an AI edit alert whose flagged text was all already on the page
# before the student's edit. Finds the earlier edits that added that text,
# checks up to MAX_CHECKS of them with Pangram, and creates a
# PreexistingAiTextAlert if any of them is flagged, since the edit that added
# the text may hold more AI text than the part the student's edit included.
class CheckOriginEditsWithPangram
  DETECTOR_KEY = CheckRevisionWithPangram::DETECTOR_KEY
  MAX_CHECKS = 3
  # Edits from before ChatGPT's public release are not checked.
  EARLIEST_CHECKED_EDIT = Time.utc(2022, 11, 30)

  # Each checked origin is { rev_id:, username:, timestamp:, words:,
  # max_ai_likelihood:, pangram_share_link:, flagged:, already_alerted: }
  attr_reader :checked_origins

  # passages: the pre-existing flagged passages, as found in parent_rev_id
  def initialize(ai_edit_alert:, parent_rev_id:, passages:)
    @ai_edit_alert = ai_edit_alert
    @parent_rev_id = parent_rev_id
    @passages = passages
    @wiki = ai_edit_alert.wiki
    @checked_origins = []
    perform unless already_followed_up?
  end

  private

  def perform
    candidates.each { |origin| check(origin) }
    create_alert if @checked_origins.any? { |origin| alertable?(origin) }
  end

  def already_followed_up?
    PreexistingAiTextAlert.exists?(revision_id: @ai_edit_alert.revision_id)
  end

  def candidates
    FindOriginRevisions.new(wiki: @wiki, article: @ai_edit_alert.article,
                            rev_id: @parent_rev_id, passages: @passages)
                       .origins
                       .select { |origin| origin[:timestamp] >= EARLIEST_CHECKED_EDIT }
                       .first(MAX_CHECKS)
  end

  def check(origin)
    parser = stored_result(origin[:rev_id]) || score(origin)
    return if parser.nil?

    @checked_origins << origin.merge(
      timestamp: origin[:timestamp].iso8601,
      max_ai_likelihood: parser.max_ai_likelihood,
      pangram_share_link: parser.pangram_share_link,
      flagged: parser.max_ai_likelihood > CheckRevisionWithPangram::AI_LIKELY_THRESHOLD,
      already_alerted: AiEditAlert.exists?(revision_id: origin[:rev_id])
    )
  end

  # An edit that already had its own AI edit alert was flagged to its editor then.
  def alertable?(origin)
    origin[:flagged] && !origin[:already_alerted]
  end

  # A revision scored before, by any check, is not billed again.
  def stored_result(rev_id)
    score = RevisionAiScore.where(revision_id: rev_id, wiki_id: @wiki.id, check_type: DETECTOR_KEY)
                           .where.not(avg_ai_likelihood: nil).last
    score && detector.parse(score.details)
  end

  def score(origin)
    text = GetRevisionPlaintext.new(origin[:rev_id], @wiki).plain_text
    return if text.nil? || text.length < CheckRevisionWithPangram::MIN_PLAIN_TEXT_LENGTH

    parser = detector.score(text)
    record_score(origin, parser)
    parser
  rescue *AiDetector.recoverable_errors => e
    # Not retried: a retry would re-bill the checks that already succeeded.
    Sentry.capture_exception(e, level: 'warning',
                                extra: { revision_id: origin[:rev_id],
                                         ai_edit_alert_id: @ai_edit_alert.id })
    nil
  end

  def record_score(origin, parser)
    RevisionAiScore.create!(
      revision_id: origin[:rev_id], wiki_id: @wiki.id,
      article_id: @ai_edit_alert.article_id, course_id: @ai_edit_alert.course_id,
      user_id: User.find_by(username: origin[:username])&.id,
      revision_datetime: origin[:timestamp],
      avg_ai_likelihood: parser.average_ai_likelihood,
      max_ai_likelihood: parser.max_ai_likelihood,
      details: parser.clean_result,
      check_type: DETECTOR_KEY, check_origin: RevisionAiScore::ORIGIN_EDIT_ORIGIN
    )
  end

  def create_alert
    alert = PreexistingAiTextAlert.create!(
      revision_id: @ai_edit_alert.revision_id, user_id: @ai_edit_alert.user_id,
      course_id: @ai_edit_alert.course_id, article_id: @ai_edit_alert.article_id,
      details: { article_title: @ai_edit_alert.article_title,
                 ai_edit_alert_id: @ai_edit_alert.id,
                 origin_edits: @checked_origins }
    )
    alert.send_alert_emails
  end

  def detector
    AiDetector.for(DETECTOR_KEY)
  end
end
