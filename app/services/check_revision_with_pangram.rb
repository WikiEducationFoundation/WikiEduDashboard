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
    fetch_parent_revision

    if @parentid.zero?
      # If it's first revision, we just
      # get the HTML for it.
      fetch_revision_html
    else
      # If it's not the first revision, we want
      # to isolate the new content. Strategy here
      # is to get the diff table, extracted the added
      # wikitext and combine it into one string,
      # then send that through Wikipedia's parser to get HTML
      fetch_diff_table
      generate_wikitext_from_diff_table
      fetch_parsed_changed_wikitext
    end
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

  def fetch_parent_revision
    # https://en.wikipedia.org/w/api.php?action=query&prop=revisions&revids=1315427810&rvprop=ids&format=json
    parentid_params = { prop: 'revisions', revids: @mw_rev_id, rvprop: 'ids' }
    resp = @wiki_api.query parentid_params
    page_id = resp.data['pages'].keys.first
    @parentid = resp.data.dig('pages', page_id, 'revisions').first['parentid']
  end

  # Use action=compare to get a diff table
  # https://en.wikipedia.org/w/api.php?action=compare&torev=1315427810&fromrev=1315426424&difftype=table
  def fetch_diff_table
    diff_params = { torev: @mw_rev_id, fromrev: @parentid, difftype: 'table' }
    resp = @wiki_api.send(:api_client).send('action', 'compare', diff_params)
    @article_title = resp.data.dig('totitle')
    @diff_table = resp.data['*']
  end

  def generate_wikitext_from_diff_table
    doc = Nokogiri::HTML(@diff_table)
    # Collect all the '.diff-addedline' table cells.
    # These represent all the sections of wikitext that were either added or changed,
    # IE, the right side of a traditional wikitext diff table without the unchanged
    # .diff-context cells.
    @changed_wikitext = doc.css('.diff-addedline').map(&:text).reject(&:empty?).join("\n\n")
  end

  def fetch_parsed_changed_wikitext
    parse_params = { text: @changed_wikitext, contentmodel: 'wikitext' }
    resp = @wiki_api.send(:api_client).send('action', 'parse', parse_params)
    @diff_html = resp.data.dig('text', '*')
  end

  def fetch_revision_html
    # https://en.wikipedia.org/w/api.php?action=parse&oldid=952185129
    params = { oldid: @mw_rev_id }
    resp = @wiki_api.send(:api_client).send('action', 'parse', params)
    @rev_html = resp.data.dig('text', '*')
    @article_title = resp.data.dig('title')
    @mw_page_id = resp.data.dig('pageid')
  end

  def generate_plaintext_from_html
    # First remove the <table> elements, which contain template content in exercise sandboxes
    # and are likely to contain non-prose in other cases.
    @cleaned_html = remove_html_tables_and_citations(@diff_html || @rev_html)
    # Convert the HTML to plain text, then remove the edit button leftovers
    @plain_text = ActionView::Base.full_sanitizer.sanitize(@cleaned_html).gsub('[edit]', '').strip
  end

  def remove_html_tables_and_citations(html)
    doc = Nokogiri::HTML(html)
    doc.xpath('//table').each(&:remove) # Exclude tables, like infoboxes
    doc.xpath('//cite').each(&:remove) # Exclude `cite` tags, which usually appear at the end
    doc.css('.mw-cite-backlink').each(&:remove) # Exclude backlinks that precede `cite` tags.

    doc.to_html
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
