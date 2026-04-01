# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/utils/wiki_url_parser"
require_dependency "#{Rails.root}/lib/utils/wikipedia_paragraph_walker"

# Fetches a Wikipedia revision and extracts claim-source pairs for newly inserted
# citations. The "claim" is the full sentence in the rendered article that contains
# each newly added inline citation, whether or not the surrounding prose is itself new.
# Returns an array of WikipediaCitation objects.
class ExtractClaimsAndSources
  attr_reader :claims_and_sources

  def initialize(diff_url)
    url_parser = WikiUrlParser.new(diff_url)
    @wiki = url_parser.wiki
    @wiki_api = WikiApi.new(@wiki)
    @claims_and_sources = []
    @new_ref_ids = nil # nil = all citations treated as new

    resolve_revision_ids(url_parser)
    extract
  end

  private

  def resolve_revision_ids(url_parser)
    diff_id = url_parser.diff
    if diff_id.nil? || diff_id.zero?
      @mw_rev_id = url_parser.oldid
      @from_rev = fetch_parent_revision_id
    else
      @mw_rev_id = diff_id
      @from_rev = url_parser.oldid
    end
  end

  def fetch_parent_revision_id
    params = { prop: 'revisions', revids: @mw_rev_id, rvprop: 'ids' }
    resp = @wiki_api.query(params)
    return nil if resp.nil? || resp.data['badrevids'].present?

    page_id = resp.data['pages']&.keys&.first
    resp.data.dig('pages', page_id, 'revisions')&.first&.fetch('parentid', nil)
  end

  def extract
    fetch_parsed_html
    return if @parsed_html.nil?

    @claims_and_sources = parse_claims_and_sources
  end

  # For new pages (no parent), fetches the full revision HTML and treats every
  # citation as new. For edits, fetches both revision HTMLs and identifies newly
  # added references by comparing source content; only those produce pairs.
  def fetch_parsed_html
    if @from_rev.nil? || @from_rev.zero?
      fetch_revision_html
    else
      compare_revisions
    end
  end

  def fetch_revision_html
    @parsed_html = fetch_html_for_revision(@mw_rev_id)
  end

  def fetch_html_for_revision(rev_id)
    params = { oldid: rev_id }
    resp = @wiki_api.send(:api_client).send('action', 'parse', params)
    resp&.data&.dig('text', '*')
  end

  def compare_revisions
    from_html = fetch_html_for_revision(@from_rev)
    fetch_revision_html
    return if @parsed_html.nil?

    from_keys = source_keys_from_html(from_html)
    @new_ref_ids = new_ref_ids_from_html(from_keys)
  end

  def source_keys_from_html(html)
    return Set.new if html.nil?

    doc = Nokogiri::HTML(html)
    Set.new(doc.css('ol.references li').filter_map { |li| source_key_from_li(li) })
  end

  # Builds the set of cite_note IDs in the "to" revision whose source content
  # does not appear in the "from" revision's reference list.
  def new_ref_ids_from_html(from_keys)
    doc = Nokogiri::HTML(@parsed_html)
    doc.css('ol.references li').each_with_object(Set.new) do |li, new_ids|
      next if li['id'].nil? || from_keys.include?(source_key_from_li(li))

      new_ids << li['id']
    end
  end

  # Returns a stable key for a reference <li>: the COinS span title if present,
  # otherwise the reference text with the backlink removed.
  def source_key_from_li(li)
    span = li.at_css('span.Z3988')
    return span['title'] if span

    li_clone = li.dup
    li_clone.css('.mw-cite-backlink').each(&:remove)
    li_clone.at_css('.reference-text')&.text&.strip
  end

  def parse_claims_and_sources
    doc = Nokogiri::HTML(@parsed_html)
    ref_map = build_reference_map(doc)

    doc.xpath('//table').each(&:remove)
    doc.xpath('//figure').each(&:remove)
    doc.xpath('//img').each(&:remove)

    walker = WikipediaParagraphWalker.new(@new_ref_ids, ref_map)
    doc.css('p').flat_map { |para| walker.pairs_from(para) }
  end

  def build_reference_map(doc)
    doc.css('ol.references li').each_with_object({}) do |li, map|
      next unless li['id']

      map[li['id']] = {
        source:      WikipediaSource.from_reference_li(li),
        pages:       WikipediaSource.pages_from_li(li),
        access_date: WikipediaSource.access_date_from_li(li)
      }
    end
  end
end
