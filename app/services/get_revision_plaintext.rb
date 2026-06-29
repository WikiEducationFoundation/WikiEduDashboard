# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_api/article_content"
require_dependency "#{Rails.root}/lib/wiki_api/diff_wikitext_extractor"

class GetRevisionPlaintext
  attr_reader :plain_text, :article_title

  def initialize(mw_rev_id, wiki, diff_mode: true, from_rev: nil)
    @wiki = wiki
    @mw_rev_id = mw_rev_id
    @diff_mode = diff_mode
    @from_rev = from_rev
    @article_content = WikiApi::ArticleContent.new(@wiki)

    generate_plaintext
  end

  private

  def generate_plaintext
    # In Diff Mode, by default we are getting the diff for a single edit,
    # so we fetch the mw_rev_id of the parent revision.
    if @diff_mode && !@from_rev
      fetch_parent_revision_id
      return if @parentid.nil?
      @from_rev = @parentid
    end

    if !@diff_mode || @from_rev.zero?
      # If there's no `from_rev`, we just
      # get the HTML for the requested revision.
      fetch_revision_html
    else
      # If it's diff mode and not the first revision, we want
      # to isolate the new content. Strategy here
      # is to get the diff table, extracted the added
      # wikitext and combine it into one string,
      # then send that through Wikipedia's parser to get HTML
      fetch_diff_table
      return if @diff_table.nil?
      generate_wikitext_from_diff_table
      fetch_parsed_changed_wikitext
    end
    generate_plaintext_from_html
  end

  def fetch_parent_revision_id
    @parentid = @article_content.parent_revision_id(@mw_rev_id)
  end

  def fetch_revision_html
    result = @article_content.revision_html(@mw_rev_id)
    @rev_html = result[:html]
    @article_title = result[:title]
    @mw_page_id = result[:page_id]
  end

  # Use action=compare to get a diff table
  # https://en.wikipedia.org/w/api.php?action=compare&torev=1315427810&fromrev=1315426424&difftype=table
  def fetch_diff_table
    result = @article_content.revision_diff(@from_rev, @mw_rev_id)
    return if result.nil?
    @article_title = result[:title]
    @mw_page_id = result[:page_id]
    @diff_table = result[:diff_html]
  end

  # Extracts only the changed wikitext from the diff table,
  # excluding pre-existing content when new text is an
  # independent sentence addition.
  def generate_wikitext_from_diff_table
    @changed_wikitext = WikiApi::DiffWikitextExtractor.new(@diff_table).changed_wikitext
  end

  def fetch_parsed_changed_wikitext
    @diff_html = @article_content.parse_wikitext(@changed_wikitext)
  end

  def generate_plaintext_from_html
    # First remove the <table> elements, which contain template content in exercise sandboxes
    # and are likely to contain non-prose in other cases.
    @cleaned_html = remove_non_prose_html_elements(@diff_html || @rev_html)
    # Convert the HTML to plain text
    @plain_text = ActionView::Base.full_sanitizer.sanitize(@cleaned_html)
    # Remove the edit button leftovers
    @plain_text = @plain_text.gsub('[edit]', '').strip
    # Remove inline citation leftovers
    @plain_text = @plain_text.gsub(/\[\d+\]/, '')
  end

  def remove_non_prose_html_elements(html)
    doc = Nokogiri::HTML(html)
    doc.xpath('//table').each(&:remove) # Exclude tables, like infoboxes
    doc.xpath('//cite').each(&:remove) # Exclude `cite` tags, which usually appear at the end
    doc.css('.mw-cite-backlink').each(&:remove) # Exclude backlinks that precede `cite` tags.

    doc.xpath('//figure').each(&:remove) # Exclude figure elements (images + captions)
    doc.xpath('//img').each(&:remove) # Exclude any remaining image elements

    doc.to_html
  end
end
