# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/claim_verification/claim"
require_dependency "#{Rails.root}/lib/claim_verification/citation"
require_dependency "#{Rails.root}/lib/claim_verification/sentence_segmenter"

module ClaimVerification
  # Structural extraction of cited claims and their citations from
  # rendered revision HTML (MediaWiki parser output). Pure Nokogiri;
  # no network calls, no LLM.
  class ClaimCitationExtractor
    attr_reader :claims, :citations

    def initialize(html)
      @doc = Nokogiri::HTML(html)
      @claims = []
      @citations = []
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
                                   archive_urls:)
      end
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

    def extract_claims
      remove_non_prose_elements
      @doc.css('p').each do |paragraph|
        @claims.concat(paragraph_claims(paragraph))
      end
    end

    def remove_non_prose_elements
      @doc.css('table, figure, ol.references').each(&:remove)
    end

    # Returns one Claim per sentence that has at least one reference
    # marker attached. Cited sentences carry the paragraph text so far
    # as context, since an end-of-passage citation may cover more than
    # its own sentence.
    def paragraph_claims(paragraph)
      segments = SentenceSegmenter.new(paragraph).segments
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
