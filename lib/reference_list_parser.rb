# frozen_string_literal: true

# Parses the rendered references section of a Wikipedia article.
# Given a Nokogiri doc of parsed article HTML, builds an index of
# citation details keyed by `cite_note` id, so that inline reference
# markers (`sup.reference`) can be resolved to the sources they cite.
class ReferenceListParser
  # Cite templates render as `<cite class="citation web cs1">` (or
  # book/journal/news/etc). These are the type classes we recognize.
  SOURCE_TYPES = %w[
    web book journal news magazine encyclopaedia conference
    thesis report pressrelease podcast episode AV-media map arxiv
  ].freeze

  attr_reader :citations

  def initialize(doc)
    @doc = doc
    @citations = {}
    parse_reference_list
  end

  private

  def parse_reference_list
    @doc.css('li[id^="cite_note-"]').each do |li|
      reference_text = li.at_css('.reference-text')
      next if reference_text.nil?
      @citations[li['id']] = parse_citation(li['id'], clean_reference_node(reference_text))
    end
  end

  # Removes rendering noise from a reference: TemplateStyles tags
  # and the COinS metadata span, which contribute no readable text.
  def clean_reference_node(reference_text)
    cleaned = reference_text.dup
    cleaned.css('style, link, .Z3988').each(&:remove)
    cleaned
  end

  def parse_citation(ref_id, reference_node)
    urls = external_urls(reference_node)
    {
      ref_id:,
      citation_text: reference_node.text.squish,
      source_type: source_type(reference_node),
      url: urls.first,
      urls:,
      web_accessible: urls.any?
    }
  end

  # External source links render as `<a class="external" href="https://...">`.
  # Internal links (ISBN lookups, wikilinks) are relative and excluded.
  def external_urls(reference_node)
    reference_node.css('a.external').filter_map do |link|
      href = link['href']
      href if href&.start_with?('http')
    end.uniq
  end

  # A templated citation's type comes from its `<cite>` classes,
  # e.g. `citation book cs1` => 'book'. Hand-written references
  # have no `<cite>` element and get 'unknown'.
  def source_type(reference_node)
    cite = reference_node.at_css('cite')
    return 'unknown' if cite.nil?
    type = (cite.classes & SOURCE_TYPES).first
    type || 'unknown'
  end
end
