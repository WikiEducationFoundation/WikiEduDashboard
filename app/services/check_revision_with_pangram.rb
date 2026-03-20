# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/pangram_api"
require_dependency "#{Rails.root}/lib/ai/pangram_response_parser"

class CheckRevisionWithPangram
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
    fetch_pangram_inference
    parse_pangram_response
    create_revision_ai_score

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
  def already_checked?
    RevisionAiScore.where(
      revision_id: @mw_rev_id,
      wiki_id: @wiki.id,
      article_id: @article.id
    ).where.not(avg_ai_likelihood: nil).exists?
  end

  def fetch_pangram_inference
    @pangram_result = PangramApi.v3.inference @plain_text
  end

  def parse_pangram_response
    @parser = PangramResponseParser.new(RevisionAiScore::PANGRAM_V3_KEY, @pangram_result)
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

  # Imports data into the RevisionAiScores table
  def create_revision_ai_score
    RevisionAiScore.create(revision_id: @mw_rev_id,
                           wiki_id: @wiki.id,
                           article_id:  @article.id,
                           course_id: @course_id,
                           user_id: @user_id,
                           revision_datetime: @rev_datetime,
                           avg_ai_likelihood: @parser.average_ai_likelihood,
                           max_ai_likelihood: @parser.max_ai_likelihood,
                           details: @parser.clean_pangram_result,
                           check_type: RevisionAiScore::PANGRAM_V3_KEY)
  end
end
