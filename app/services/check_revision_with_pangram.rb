# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/pangram_api"

class CheckRevisionWithPangram
  def initialize(wiki_id, mw_rev_id, user_id, course_id)
    @wiki = Wiki.find wiki_id
    @mw_rev_id = mw_rev_id
    @user_id = user_id
    @course_id = course_id

    check unless already_checked?
  end

  def check
    fetch_revision_html
    generate_plaintext_from_html
    fetch_pangram_inference

    generate_alert if ai_likely?

    cache_pangram_check_timestamp
  end

  private

  def cache_key
    "pangram_#{@wiki.domain}_#{@mw_rev_id}"
  end

  def already_checked?
    Rails.cache.read(cache_key).present?
  end

  def cache_pangram_check_timestamp
    Rails.cache.write(cache_key, Time.current.to_s, expires_in: 7.days)
  end

  def fetch_revision_html
    # https://en.wikipedia.org/w/api.php?action=parse&oldid=952185129
    params = { oldid: @mw_rev_id }
    resp = WikiApi.new(@wiki).send(:api_client).send('action', 'parse', params)
    @rev_html = resp.data.dig('text', '*')
    @article_title = resp.data.dig('title')
    @mw_page_id = resp.data.dig('pageid')
  end

  def generate_plaintext_from_html
    # Convert the HTML to plain text, then remove the edit button leftovers
    @plain_text = ActionView::Base.full_sanitizer.sanitize(@rev_html).gsub('[edit]', '')
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
    alert = Alert.create!(type: 'AiEditAlert',
                          revision_id: @mw_rev_id,
                          user_id: @user_id,
                          course_id: @course_id,
                          article_id: @article&.id,
                          details: pangram_details)
    alert.email_content_expert
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
      ai_likelihood:,
      average_ai_likelihood:,
      max_ai_likelihood:,
      fraction_ai_content:,
      predicted_ai_window_count:,
      predicted_llm:,
      pangram_share_link:
    }
  end

  def pangram_prediction
    @pangram_result['prediction']
  end

  def ai_likelihood
    @pangram_result['ai_likelihood']
  end

  def average_ai_likelihood
    @pangram_result['avg_ai_likelihood']
  end

  def max_ai_likelihood
    @pangram_result['max_ai_likelihood']
  end

  def fraction_ai_content
    @pangram_result['fraction_ai_content']
  end

  def predicted_ai_window_count
    @pangram_result['window_likelihoods'].count { |likelihood| likelihood > 0.5 }
  end

  # TODO: Handle unclear results where Pangram is has multiple
  # similarly-likely predictions.
  def predicted_llm
    return nil if fraction_ai_content.zero?
    @pangram_result['llm_prediction'].key(@pangram_result['llm_prediction'].values.max)
  end

  def pangram_share_link
    @pangram_result['dashboard_link']
  end
end
