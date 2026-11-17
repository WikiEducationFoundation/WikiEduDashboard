# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/check"

module ArticleAuditing
  module Checks
    # Flags a draft on English Wikipedia written mostly in another language
    # (WP:ENGLISHPLEASE). A cheap heuristic rather than an LLM call: running
    # English prose is roughly 40% common function words, and text in most
    # other languages has very few of them.
    class Language < Check
      KEY = 'language.not_english'
      CATEGORY = 'policy'

      MIN_WORDS = 100
      MIN_ENGLISH_SHARE = 0.15
      FUNCTION_WORDS = %w[
        the of and to in a is was for on that with as by at from it an be are were or
        his her their its which this has have had not but also who after they he she
      ].to_set.freeze

      def applies_to?(context)
        context.wiki.language == 'en'
      end

      def run(context)
        words = context.plaintext.downcase.scan(/\p{L}+/)
        return output([]) if words.size < MIN_WORDS
        share = words.count { |word| FUNCTION_WORDS.include?(word) }.fdiv(words.size)
        usage = { 'english_share' => share.round(3) }
        return output([], usage:) if share >= MIN_ENGLISH_SHARE
        output([not_english], usage:)
      end

      private

      def not_english
        finding(severity: 'must_fix', **coded(:not_english), policy_refs: %w[WP:ENGLISHPLEASE])
      end
    end
  end
end
