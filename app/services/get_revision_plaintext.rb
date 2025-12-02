# frozen_string_literal: true

class GetRevisionPlaintext
  attr_reader :plain_text, :article_title

  def initialize(mw_rev_id, wiki)
    @wiki = wiki
    @mw_rev_id = mw_rev_id
    @wiki_api = WikiApi.new(@wiki)

    generate_plaintext
  end

  private

  def generate_plaintext
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

  def fetch_revision_html
    # https://en.wikipedia.org/w/api.php?action=parse&oldid=952185129
    params = { oldid: @mw_rev_id }
    resp = @wiki_api.send(:api_client).send('action', 'parse', params)
    @rev_html = resp.data.dig('text', '*')
    @article_title = resp.data.dig('title')
    @mw_page_id = resp.data.dig('pageid')
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
end
