# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/check"

module ArticleAuditing
  module Checks
    # Sentences run together with no space after the full stop, as in
    # "first sentence.Second sentence".
    class SentenceSpacing < Check
      KEY = 'mos.sentence_spacing'
      CATEGORY = 'mos'
      MAX_FINDINGS = 5

      # Two lowercase letters before the stop keeps out initialisms like U.S.A.
      MISSING_SPACE = /[a-z]{2}[.!?](?=[A-Z][a-z])/

      def run(context)
        wikitext = context.parsed_wikitext
        masked = wikitext.masked
        indexes = masked.to_enum(:scan, MISSING_SPACE).map { Regexp.last_match.begin(0) }
        indexes.reject! { |index| inside_link?(masked, index) }
        findings = indexes.first(MAX_FINDINGS).map do |index|
          finding(severity: 'suggestion', **coded(:missing_space, count: indexes.size),
                  section: wikitext.section_at(index).title,
                  quote: excerpt(masked, index, length: 40))
        end
        output(findings)
      end

      private

      # Inside a [[wikilink]] or [external link], where a title or URL may
      # legitimately run together.
      def inside_link?(text, index)
        open = text.rindex('[', index)
        open && (text.rindex(']', index).nil? || text.rindex(']', index) < open)
      end
    end
  end
end
