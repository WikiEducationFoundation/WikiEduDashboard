# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/claim_verification/claim"
require_dependency "#{Rails.root}/lib/claim_verification/citation"
require_dependency "#{Rails.root}/lib/claim_verification/sentence_segmenter"

module ClaimVerification
  # Structural extraction of cited claims and their citations from
  # rendered revision HTML (MediaWiki parser output). Pure Nokogiri;
  # no network calls, no LLM.
  class ClaimCitationExtractor
    attr_reader :claims, :citations, :paragraphs

    def initialize(html)
      @doc = Nokogiri::HTML(html)
      @claims = []
      @citations = []
      @paragraphs = []
      extract_citations
      extract_claims
    end

    private

    def extract_citations
      @doc.css('ol.references li[id^="cite_note"]').each do |li|
        li.css('style, link').each(&:remove)
        urls = external_urls(li)
        archive_urls, source_urls = urls.partition { |url| url.include?('web.archive.org') }
        @citations << Citation.new(ref_id: li['id'],
                                   cite_html: citation_html(li),
                                   cite_text: citation_text(li),
                                   urls: source_urls,
                                   archive_urls:,
                                   unresolved: unresolved_reference?(li))
      end
    end

    # A reference invoked but not defined in this render (eg a named ref whose
    # definition lives elsewhere in the article) renders as a Cite-extension
    # error in its reference-list entry. We key on that extension's error
    # marker — emitted for every unresolved-ref pattern regardless of the
    # citation template/format inside, and language-independent — rather than
    # on any particular template or wording. This is only a trigger to consult
    # the full-revision render, never a correctness gate.
    def unresolved_reference?(reference_li)
      reference_li.at_css('.mw-ext-cite-error, .error').present?
    end

    def external_urls(reference_li)
      reference_li.css('a.external').filter_map { |a| a['href'] }.uniq
    end

    def citation_html(reference_li)
      cite = reference_li.at_css('cite')
      (cite || reference_text_node(reference_li))&.inner_html&.strip
    end

    def citation_text(reference_li)
      node = reference_li.at_css('cite') || reference_text_node(reference_li)
      node&.text&.strip
    end

    # Bare refs (no citation template) have no <cite> element; their
    # content sits directly in the .reference-text span.
    def reference_text_node(reference_li)
      reference_li.at_css('.reference-text')
    end

    # Segments each prose paragraph once: `paragraphs` keeps every sentence
    # (for rendering the article in context) while `claims` keeps only the
    # cited ones.
    def extract_claims
      remove_non_prose_elements
      @doc.css('p').each do |paragraph|
        segments = SentenceSegmenter.new(paragraph).segments
        next if segments.empty?
        @paragraphs << segments
        @claims.concat(claims_from(segments))
      end
    end

    def remove_non_prose_elements
      @doc.css('table, figure, ol.references').each(&:remove)
    end

    # One Claim per cited sentence. Cited sentences carry the paragraph text
    # so far as context, since an end-of-passage citation may cover more than
    # its own sentence.
    def claims_from(segments)
      context = +''
      segments.filter_map do |segment|
        context << ' ' unless context.empty?
        context << segment[:sentence]
        next if segment[:ref_ids].empty?
        Claim.new(sentence: segment[:sentence], ref_ids: segment[:ref_ids],
                  context: context.dup)
      end
    end
  end
end
