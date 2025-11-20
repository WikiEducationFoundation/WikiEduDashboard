# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/pangram_api"

class CheckRevisionWithPangram
  def initialize(attrs)
    @wiki = Wiki.find attrs['wiki_id']
    @mw_rev_id = attrs['mw_rev_id']
    @user_id = attrs['user_id']
    @course_id = attrs['course_id']
    @wiki_api = WikiApi.new(@wiki)
    @rev_datetime = Time.zone.at(attrs['revision_timestamp'])
    @article = Article.find(attrs['article_id'])

    check unless already_checked?
  end

  def check
    fetch_parent_revision
    return if @parentid.nil?

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
    # Skip the API call if the plain text is too short.
    return if @plain_text.length < MIN_PLAIN_TEXT_LENGTH
    fetch_pangram_inference
    create_revision_ai_score

    generate_alert if ai_likely?
  end

  private

  MIN_PLAIN_TEXT_LENGTH = 500

  PANGRAM_CHECK_TYPE = 'Pangram 2.0'

  def cache_key
    "pangram_#{@wiki.domain}_#{@mw_rev_id}"
  end

  # Determines whether the check was already performed for the given revision,
  # based on the existence of a record in the data table with the same revision, wiki, and article,
  # where the details field is not nil.
  # A nil details field may indicate an error occurred when calling the API, so we want
  # to retrieve it again.
  def already_checked?
    # Keep this check for an initial period to avoid rechecking the revisions that were
    # checked before the table was deployed.
    return true if Rails.cache.read(cache_key).present?

    RevisionAiScore.where(
      revision_id: @mw_rev_id,
      wiki_id: @wiki.id,
      article_id: @article.id
    ).where.not(details: nil).exists?
  end

  def fetch_parent_revision
    # https://en.wikipedia.org/w/api.php?action=query&prop=revisions&revids=1315427810&rvprop=ids&format=json
    parentid_params = { prop: 'revisions', revids: @mw_rev_id, rvprop: 'ids' }
    resp = @wiki_api.query parentid_params

    if resp.data['badrevids'].present?
      Sentry.capture_message(
        "CheckRevisionWithPangram: revision #{@mw_rev_id} missing or deleted"
      )
      @parentid = nil # Indicate that the revision is missing
      return
    end

    page_id = resp.data['pages'].keys.first
    @parentid = resp.data.dig('pages', page_id, 'revisions').first['parentid']
  end

  # Use action=compare to get a diff table
  # https://en.wikipedia.org/w/api.php?action=compare&torev=1315427810&fromrev=1315426424&difftype=table
  def fetch_diff_table
    diff_params = { torev: @mw_rev_id, fromrev: @parentid, difftype: 'table' }
    resp = @wiki_api.send(:api_client).send('action', 'compare', diff_params)
    @article_title = resp.data.dig('totitle')
    @mw_page_id = resp.data.dig('toid')
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
    # Convert the HTML to plain text
    @plain_text = ActionView::Base.full_sanitizer.sanitize(@cleaned_html)
    # Remove the edit button leftovers
    @plain_text = @plain_text.gsub('[edit]', '').strip
    # Remove inline citation leftovers
    @plain_text = @plain_text.gsub(/\[\d+\]/, '')
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
