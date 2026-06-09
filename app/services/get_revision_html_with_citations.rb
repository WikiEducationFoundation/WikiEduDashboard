# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_api/article_content"
require_dependency "#{Rails.root}/lib/wiki_api/diff_wikitext_extractor"

# Fetches the rendered HTML of a revision (or of just the content added
# in a diff) with citation markup intact: <sup class="reference"> markers
# in the prose and the <ol class="references"> list with <cite> entries.
# This is the counterpart of GetRevisionPlaintext, which strips citations;
# claim verification needs them preserved so that claims can be paired
# with the sources cited for them.
class GetRevisionHtmlWithCitations
  attr_reader :html, :article_title

  def initialize(mw_rev_id, wiki, diff_mode: true, from_rev: nil)
    @wiki = wiki
    @mw_rev_id = mw_rev_id
    @diff_mode = diff_mode
    @from_rev = from_rev
    @article_content = WikiApi::ArticleContent.new(@wiki)

    generate_html
  end

  private

  def generate_html
    # In diff mode, by default we are getting the diff for a single edit,
    # so we fetch the mw_rev_id of the parent revision.
    if @diff_mode && !@from_rev
      @from_rev = @article_content.parent_revision_id(@mw_rev_id)
      return if @from_rev.nil?
    end

    if !@diff_mode || @from_rev.zero?
      fetch_revision_html
    else
      fetch_changed_content_html
    end
  end

  def fetch_revision_html
    result = @article_content.revision_html(@mw_rev_id)
    @html = result[:html]
    @article_title = result[:title]
  end

  # Isolates the new content of the edit: extract the added wikitext
  # from the diff table, then render it through Wikipedia's parser.
  def fetch_changed_content_html
    result = @article_content.revision_diff(@from_rev, @mw_rev_id)
    return if result.nil?
    @article_title = result[:title]
    changed_wikitext = WikiApi::DiffWikitextExtractor.new(result[:diff_html]).changed_wikitext
    return if changed_wikitext.empty?
    @html = @article_content.parse_wikitext(with_reference_list(changed_wikitext))
  end

  # Without an explicit <references /> tag, MediaWiki renders isolated
  # wikitext containing <ref> tags with a cite error instead of an
  # <ol class="references"> list.
  def with_reference_list(wikitext)
    "#{wikitext}\n<references />"
  end
end
