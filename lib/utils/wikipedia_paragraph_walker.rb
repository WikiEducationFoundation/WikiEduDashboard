# frozen_string_literal: true

# Extracts claim-source pairs from a single Wikipedia rendered paragraph.
# Walks the node tree in two passes: first collecting all text and citation
# events (with character positions), then finding the complete sentence that
# contains each new citation and building a WikipediaCitation for it.
#
# A citation is considered "new" when its cite_note ID is present in
# new_ref_ids (or when new_ref_ids is nil, meaning all are treated as new).
class WikipediaParagraphWalker
  def initialize(new_ref_ids, ref_map)
    @new_ref_ids = new_ref_ids
    @ref_map = ref_map
  end

  def pairs_from(paragraph)
    full_text, citations = flatten_paragraph(paragraph)
    spans = sentence_spans(full_text)
    citations.filter_map { |cit| pair_for_citation(cit, full_text, spans) }
  end

  private

  def flatten_paragraph(paragraph)
    segments = []
    collect_segments(paragraph.children, segments)
    full_text = +''
    citations = []
    segments.each do |seg|
      if seg[:type] == :text
        full_text << seg[:text]
      else
        citations << { pos: full_text.length, ref_id: seg[:ref_id] }
      end
    end
    [full_text, citations]
  end

  def collect_segments(nodes, segments)
    nodes.each do |node|
      if node.text?
        segments << { type: :text, text: node.text }
      elsif citation_node?(node)
        segments << { type: :citation, ref_id: citation_ref_id(node) }
      else
        collect_segments(node.children, segments)
      end
    end
  end

  # Returns inclusive character ranges, one per sentence, splitting on
  # sentence-ending punctuation followed by whitespace.
  def sentence_spans(text)
    spans = []
    start = 0
    text.scan(/(?<=[.!?])\s+/) do
      spans << (start..$~.begin(0))
      start = $~.end(0)
    end
    spans << (start..text.length) unless start > text.length
    spans
  end

  def pair_for_citation(cit, full_text, spans)
    return unless new_citation?(cit[:ref_id])

    ref_entry = @ref_map[cit[:ref_id]]
    return unless ref_entry.present?

    span = spans.find { |s| s.cover?(cit[:pos]) }
    return unless span

    claim_text = full_text[span].strip
    return unless claim_text.present?

    WikipediaCitation.new(
      claim:       WikipediaClaim.new(claim_text),
      source:      ref_entry[:source],
      pages:       ref_entry[:pages],
      access_date: ref_entry[:access_date]
    )
  end

  def new_citation?(ref_id)
    @new_ref_ids.nil? || @new_ref_ids.include?(ref_id)
  end

  def citation_node?(node)
    node.name == 'sup' && node['class']&.include?('reference')
  end

  def citation_ref_id(node)
    href = node.at_css('a')&.attr('href')
    href&.delete_prefix('#')
  end
end
