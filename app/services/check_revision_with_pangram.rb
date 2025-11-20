# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/pangram_api"

class CheckRevisionWithPangram
  def initialize(wiki_id, mw_rev_id, user_id, course_id)
    @wiki = Wiki.find wiki_id
    @mw_rev_id = mw_rev_id
    @user_id = user_id
    @course_id = course_id
    @wiki_api = WikiApi.new(@wiki)

    check unless already_checked?
  end

  def check
    fetch_title_and_plaintext
    fetch_pangram_inference

    generate_alert if ai_likely?

    cache_pangram_check_timestamp
  end

  private

  def fetch_title_and_plaintext
    plaintext_service = GetRevisionPlaintext.new(@mw_rev_id, @wiki)
    @article_title = plaintext_service.article_title
    @plain_text = plaintext_service.plain_text
  end

  def cache_key
    "pangram_#{@wiki.domain}_#{@mw_rev_id}"
  end

  def already_checked?
    Rails.cache.read(cache_key).present?
  end

  def cache_pangram_check_timestamp
    Rails.cache.write(cache_key, Time.current.to_s, expires_in: 7.days)
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

    find_article
    AiEditAlert.generate_alert_from_pangram(revision_id: @mw_rev_id,
                                            user_id: @user_id,
                                            course_id: @course_id,
                                            article_id: @article&.id,
                                            pangram_details:)
  end

  def alert_already_exists?
    AiEditAlert.exists?(revision_id: @mw_rev_id)
  end

  def find_article
    @article = Article.find_by(mw_page_id: @mw_page_id, wiki: @wiki)
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
end
