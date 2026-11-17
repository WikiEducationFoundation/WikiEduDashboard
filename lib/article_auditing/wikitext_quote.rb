# frozen_string_literal: true

module ArticleAuditing
  # For a finding whose quote is wikitext rather than rendered text (a cite
  # template, ''italics'', a misplaced <ref>), works out what to look for in
  # the rendered article instead.
  #
  # A quote from inside a <ref> points at that citation, so the candidates are
  # the citation's title, work and author as they appear in the reference
  # list. Any other quote is looked for with its markup stripped.
  class WikitextQuote
    REF = %r{<ref(?:\s[^>]*)?(?<!/)>(.*?)</ref>}m
    PARAMS = %w[title chapter work website journal newspaper publisher last last1 author author1]
    CITATION_PARAMS = /\|\s*(?:#{PARAMS.join('|')})\s*=\s*([^|}]+)/
    # Shorter strings match too many places to point at the right one.
    MIN_LENGTH = 8

    def initialize(quote, wikitext)
      @quote = quote.to_s
      @wikitext = wikitext.to_s
    end

    # [[kind, normalized text]] to look for, best first. The kind is
    # 'reference' for a citation in the reference list, 'text' otherwise.
    def candidates
      found = citation_candidates.map { |text| ['reference', text] }
      found << ['text', normalize(strip_markup(@quote))]
      found.select { |_, text| text.length >= MIN_LENGTH }.uniq
    end

    def self.strip_markup(text)
      stripped = text.gsub(%r{<ref[^>]*/>}, '').gsub(%r{<ref[^>]*>.*?(?:</ref>|\z)}m, '')
      stripped = stripped.gsub(/\{\{[^{}]*\}\}/, '') while stripped.match?(/\{\{[^{}]*\}\}/)
      stripped.gsub(/\{\{[^{}]*\z|\A[^{}]*\}\}/, '') # templates cut off by the quote's ends
              .gsub(/\[\[(?:[^|\]]*\|)?([^\]]*)\]\]/, '\1')
              .gsub(%r{\[https?://\S+\s+([^\]]*)\]}, '\1')
              .gsub(/'{2,}|\[\[|\]\]|<[^>]*>/, '')
              .gsub(/^[*#:;]+|^=+|=+$/, '') # list and heading markup
    end

    private

    def strip_markup(text)
      self.class.strip_markup(text)
    end

    def normalize(text)
      ArticleTextIndex.normalize(text).delete_prefix('...').delete_suffix('...').strip
    end

    # The rendered-text parts of the citation whose wikitext contains the quote.
    def citation_candidates
      needle = normalize(@quote.gsub(%r{</?ref[^>]*>}, ''))
      # A quote of nothing but ref tags would match every ref.
      return [] if needle.empty?
      ref =@wikitext.scan(REF).flatten.find { |content| normalize(content).include?(needle) }
      return [] if ref.nil?
      params = ref.scan(CITATION_PARAMS).flatten.map { |value| normalize(strip_markup(value)) }
      params + [normalize(strip_markup(ref))]
    end
  end
end
