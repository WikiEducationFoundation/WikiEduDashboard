# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/check"

module ArticleAuditing
  module Checks
    # Inline citation placement per MOS:REFPUNCT: refs go after punctuation,
    # with no space before the ref and a space after it when text follows.
    class ReferencePlacement < Check
      KEY = 'mos.reference_placement'
      CATEGORY = 'mos'
      MAX_PER_PATTERN = 5

      REF_END = %r{(?:</ref\s*>|<ref\b[^>]*/>)}i
      PATTERNS = [
        { regex: /#{REF_END}[.,;:!?]/, severity: 'should_fix', copy: :before_punctuation },
        { regex: /[^\s=|] +<ref\b/i, severity: 'should_fix', copy: :space_before },
        { regex: /#{REF_END}[[:alpha:]]/, severity: 'suggestion', copy: :no_space_after }
      ].freeze

      def run(context)
        text = context.parsed_wikitext.without_comments
        output(PATTERNS.flat_map { |pattern| findings_for(text, pattern) })
      end

      private

      def findings_for(text, pattern)
        matches = text.to_enum(:scan, pattern[:regex]).map { Regexp.last_match.begin(0) }
        matches.first(MAX_PER_PATTERN).map do |index|
          finding(severity: pattern[:severity], **coded(pattern[:copy], count: matches.size),
                  quote: excerpt(text, index), policy_refs: %w[MOS:REFPUNCT])
        end
      end
    end
  end
end
