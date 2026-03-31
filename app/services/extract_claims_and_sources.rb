# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/utils/wiki_url_parser"

# Fetches a Wikipedia diff and extracts claim-source pairs from the added content.
# Each "claim" is the sentence immediately preceding an inline citation, and
# "source" is the corresponding formatted reference text.
#
# Returns an array of hashes: [{ claim: "...", source: "..." }, ...]
class ExtractClaimsAndSources
  attr_reader :claims_and_sources

  def initialize(diff_url)
    url_parser = WikiUrlParser.new(diff_url)
    @wiki = url_parser.wiki
    @wiki_api = WikiApi.new(@wiki)
    @claims_and_sources = []

    resolve_revision_ids(url_parser)
    extract
  end

  private

  # Determines which revision is the "to" revision and which is the "from"
  # revision based on the diff URL format.
  #
  # Two common Wikipedia diff URL formats:
  #   ?diff=<new_rev>&oldid=<old_rev>  — explicit revision pair
  #   ?diff=prev&oldid=<rev>           — oldid is "to"; parent is fetched
  def resolve_revision_ids(url_parser)
    diff_id = url_parser.diff
    if diff_id.nil? || diff_id.zero?
      # diff=prev: oldid is the "to" revision; fetch its parent for "from"
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

  # For new pages (no parent revision), fetch the full revision HTML.
  # For edits to existing pages, extract only the added wikitext from
  # the diff and parse it so that <ref> tags resolve into citations.
  def fetch_parsed_html
    if @from_rev.nil? || @from_rev.zero?
      fetch_revision_html
    else
      fetch_diff_wikitext_and_parse
    end
  end

  def fetch_revision_html
    params = { oldid: @mw_rev_id }
    resp = @wiki_api.send(:api_client).send('action', 'parse', params)
    @parsed_html = resp&.data&.dig('text', '*')
  end

  # Fetches the diff table via action=compare, extracts the raw wikitext
  # of all added lines (preserving inline <ref> tags), and then sends
  # that wikitext through action=parse to produce citation-resolved HTML.
  def fetch_diff_wikitext_and_parse
    diff_params = { torev: @mw_rev_id, fromrev: @from_rev, difftype: 'table' }
    resp = @wiki_api.send(:api_client).send('action', 'compare', diff_params)
    diff_table = resp&.data&.fetch('*', nil)
    return if diff_table.nil?

    added_wikitext = extract_added_wikitext(diff_table)
    return if added_wikitext.blank?

    parse_params = { text: added_wikitext, contentmodel: 'wikitext' }
    resp = @wiki_api.send(:api_client).send('action', 'parse', parse_params)
    @parsed_html = resp&.data&.dig('text', '*')
  end

  # Extracts the raw wikitext from the diff table, limited to content that
  # was genuinely added in this edit:
  #
  # - For entirely new rows (no deleted side), the full added text is new.
  # - For modified rows (both deleted and added sides exist), only the text
  #   inside <ins class="diffchange"> elements is new; the surrounding text
  #   was already present and its citations should not be attributed to this
  #   edit.
  def extract_added_wikitext(diff_table)
    doc = Nokogiri::HTML(diff_table)
    doc.css('tr').filter_map { |row| new_wikitext_from_row(row) }.join("\n\n")
  end

  def new_wikitext_from_row(row)
    added = row.at_css('.diff-addedline')
    return nil if added.nil? || added.text.strip.empty?

    deleted = row.at_css('.diff-deletedline')
    if deleted.nil? || deleted.text.strip.empty?
      added.text.strip
    else
      ins_texts = added.css('ins.diffchange').map(&:text)
      ins_texts.join(' ').strip.presence
    end
  end

  def parse_claims_and_sources
    doc = Nokogiri::HTML(@parsed_html)
    ref_map = build_reference_map(doc)

    # Remove non-prose elements before scanning paragraphs
    doc.xpath('//table').each(&:remove)
    doc.xpath('//figure').each(&:remove)
    doc.xpath('//img').each(&:remove)

    doc.css('p').flat_map { |para| extract_paragraph_pairs(para, ref_map) }
  end

  # Builds a map from cite_note IDs (e.g. "cite_note-1") to the formatted
  # reference text found in the <ol class="references"> section.
  def build_reference_map(doc)
    doc.css('ol.references li').each_with_object({}) do |li, map|
      next unless li['id']

      li_clone = li.dup
      li_clone.css('.mw-cite-backlink').each(&:remove)
      map[li['id']] = li_clone.css('.reference-text').text.strip
    end
  end

  # Walks the child nodes of a paragraph, accumulating text until a
  # <sup class="reference"> citation marker is encountered. The last
  # complete sentence before the citation is recorded as the claim.
  def extract_paragraph_pairs(paragraph, ref_map)
    pairs = []
    current_text = ''

    paragraph.children.each do |node|
      if node.text?
        current_text += node.text
      elsif citation_node?(node)
        ref_id = citation_ref_id(node)
        source = ref_map[ref_id]
        if source.present?
          claim = last_sentence(current_text)
          pairs << { claim: claim.strip, source: } if claim.present?
        end
        # Reset so the next citation is paired with the sentence after this one
        current_text = ''
      else
        # Inline elements (links, emphasis, etc.) — include their text
        current_text += node.text
      end
    end

    pairs
  end

  def citation_node?(node)
    node.name == 'sup' && node['class']&.include?('reference')
  end

  def citation_ref_id(node)
    href = node.at_css('a')&.attr('href')
    href&.delete_prefix('#')
  end

  # Splits text on sentence-ending punctuation and returns the last sentence,
  # which is the prose claim most directly associated with the following citation.
  def last_sentence(text)
    sentences = text.strip.split(/(?<=[.!?])\s+/)
    sentences.last&.strip
  end
end
