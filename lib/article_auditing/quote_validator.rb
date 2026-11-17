# frozen_string_literal: true

module ArticleAuditing
  # Guards against hallucinated locations: confirms that each finding's quote
  # actually appears in the revision, comparing against both the wikitext and
  # the rendered prose with whitespace and case normalized. Findings whose
  # quote can't be found are kept but marked quote_verified: false, so the
  # report can say so and the rate can be tracked per check.
  class QuoteValidator
    def initialize(context)
      @haystacks = [context.wikitext, context.plaintext].map { |text| normalize(text) }
    end

    # Sets location.quote_verified on each finding that has a quote. Returns
    # the number of quotes that could not be found.
    def mark!(findings)
      findings.count do |finding|
        location = finding['location']
        next false if location['quote'].blank?
        location['quote_verified'] = found?(location['quote'])
        !location['quote_verified']
      end
    end

    def found?(quote)
      needle = normalize(quote).delete_prefix('...').delete_suffix('...').strip
      return true if needle.empty?
      @haystacks.any? { |haystack| haystack.include?(needle) }
    end

    private

    def normalize(text)
      text.to_s.tr('“”‘’', %(""'')).gsub(/[[:space:]]+/, ' ').downcase.strip
    end
  end
end
