# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/ai/ai_detector"

# Creates the alert for a flagged student edit whose flagged text was all
# already on the page before that edit. The earlier edits that added the text
# may hold more AI text than the part the student's edit included, so this
# finds them, checks up to MAX_CHECKS of them with Pangram, and creates a
# PreexistingAiTextAlert if any is flagged. Otherwise the edit gets the
# regular AiEditAlert. Either way, the edit gets one alert.
class CheckOriginEditsWithPangram
  DETECTOR_KEY = CheckRevisionWithPangram::DETECTOR_KEY
  MAX_CHECKS = 3
  # Edits from before ChatGPT's public release are not checked.
  EARLIEST_CHECKED_EDIT = Time.utc(2022, 11, 30)

  # Each checked origin is { rev_id:, username:, timestamp:, words:,
  # max_ai_likelihood:, pangram_share_link:, flagged:, already_alerted: }
  attr_reader :checked_origins

  # attributes: see OriginEditAiCheckWorker.schedule
  # check_origins: false skips straight to the regular AiEditAlert
  def initialize(attributes, check_origins: true)
    @mw_rev_id = attributes['mw_rev_id']
    @wiki = Wiki.find(attributes['wiki_id'])
    @article = Article.find(attributes['article_id'])
    @course_id = attributes['course_id']
    @user_id = attributes['user_id']
    @article_title = attributes['article_title']
    @parent_rev_id = attributes['parent_rev_id']
    @passages = attributes['passages']
    @checked_origins = []
    perform(check_origins) unless alert_exists?
  end

  private

  def perform(check_origins)
    candidates.each { |origin| check(origin) } if check_origins
    if @checked_origins.any? { |origin| alertable?(origin) }
      create_preexisting_ai_text_alert
    else
      create_ai_edit_alert
    end
  end

  def alert_exists?
    AiEditAlert.exists?(revision_id: @mw_rev_id) ||
      PreexistingAiTextAlert.exists?(revision_id: @mw_rev_id)
  end

  def candidates
    FindOriginRevisions.new(wiki: @wiki, article: @article,
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
                                         edit_revision_id: @mw_rev_id })
    nil
  end

  def record_score(origin, parser)
    RevisionAiScore.create!(
      revision_id: origin[:rev_id], wiki_id: @wiki.id,
      article_id: @article.id, course_id: @course_id,
      user_id: User.find_by(username: origin[:username])&.id,
      revision_datetime: origin[:timestamp],
      avg_ai_likelihood: parser.average_ai_likelihood,
      max_ai_likelihood: parser.max_ai_likelihood,
      details: parser.clean_result,
      check_type: DETECTOR_KEY, check_origin: RevisionAiScore::ORIGIN_EDIT_ORIGIN
    )
  end

  # Pangram's results for the student's edit, as CheckRevisionWithPangram recorded them.
  def edit_pangram_details
    score = RevisionAiScore.where(revision_id: @mw_rev_id, wiki_id: @wiki.id,
                                  article_id: @article.id, check_type: DETECTOR_KEY,
                                  check_origin: RevisionAiScore::COURSE_UPDATE_ORIGIN)
                           .where.not(avg_ai_likelihood: nil).last
    detector.parse(score.details).pangram_details.merge(flagged_text_preexisting: true)
  end

  def create_preexisting_ai_text_alert
    details = edit_pangram_details.merge(article_title: @article_title,
                                         origin_edits: @checked_origins)
    alert = PreexistingAiTextAlert.create!(revision_id: @mw_rev_id, user_id: @user_id,
                                           course_id: @course_id, article_id: @article.id,
                                           details:)
    alert.send_alert_emails
  end

  def create_ai_edit_alert
    AiEditAlert.generate_alert_from_pangram(revision_id: @mw_rev_id, user_id: @user_id,
                                            course_id: @course_id, article_id: @article.id,
                                            article_title: @article_title,
                                            pangram_details: edit_pangram_details)
  end

  def detector
    AiDetector.for(DETECTOR_KEY)
  end
end
