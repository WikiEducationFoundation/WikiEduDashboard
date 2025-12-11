# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/pangram_api"

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
    create_revision_ai_score

    generate_alert if ai_likely?
  end

  private

  def fetch_title_and_plaintext
    plaintext_service = GetRevisionPlaintext.new(@mw_rev_id, @wiki)
    @article_title = plaintext_service.article_title
    @plain_text = plaintext_service.plain_text
  end

  PANGRAM_CHECK_TYPE = 'Pangram 2.0'

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
    @pangram_result = PangramApi.new.inference @plain_text
  end

  def ai_likely?
    # As a start, we'll just look at the most-likely window.
    # In many cases, the max is 1.0, but we'll be a little
    # more conservative.
    max_ai_likelihood > 0.9
  end

  def generate_alert
    return if alert_already_exists?

    AiEditAlert.generate_alert_from_pangram(revision_id: @mw_rev_id,
                                            user_id: @user_id,
                                            course_id: @course_id,
                                            article_id: @article.id,
                                            pangram_details:)
  end

  def alert_already_exists?
    AiEditAlert.exists?(revision_id: @mw_rev_id)
  end

  def pangram_details
    {
      article_title: @article_title,
      pangram_prediction:,
      headline_result:,
      average_ai_likelihood:,
      max_ai_likelihood:,
      fraction_human_content:,
      fraction_ai_content:,
      fraction_mixed_content:,
      window_likelihoods:,
      predicted_ai_window_count:,
      pangram_share_link:,
      pangram_version:
    }
  end

  def pangram_prediction
    @pangram_result['prediction']
  end

  def average_ai_likelihood
    @pangram_result['avg_ai_likelihood']
  end

  def max_ai_likelihood
    @pangram_result['max_ai_likelihood']
  end

  def fraction_human_content
    @pangram_result['fraction_human']
  end

  def fraction_ai_content
    @pangram_result['fraction_ai']
  end

  def fraction_mixed_content
    @pangram_result['fraction_mixed']
  end

  def headline_result
    @pangram_result['headline']
  end

  def pangram_version
    @pangram_result['version']
  end

  def window_likelihoods
    @pangram_result['window_likelihoods']
  end

  def predicted_ai_window_count
    @pangram_result['window_likelihoods'].count { |likelihood| likelihood > 0.5 }
  end

  def pangram_share_link
    @pangram_result['dashboard_link']
  end

  # Deletes text field from the pangram response to avoid storing that into the db
  def clean_pangram_result
    result = @pangram_result.dup
    result.delete('text')
    if result['windows'].is_a?(Array)
      result['windows'] = result['windows'].map { |w| w.except('text') }
    end
    result
  end

  # Imports data into the RevisionAiScores table
  def create_revision_ai_score
    RevisionAiScore.create(revision_id: @mw_rev_id,
                           wiki_id: @wiki.id,
                           article_id:  @article.id,
                           course_id: @course_id,
                           user_id: @user_id,
                           revision_datetime: @rev_datetime,
                           avg_ai_likelihood: average_ai_likelihood,
                           max_ai_likelihood: max_ai_likelihood,
                           details: clean_pangram_result,
                           check_type: PANGRAM_CHECK_TYPE)
  end
end
