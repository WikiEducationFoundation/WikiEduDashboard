# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/check"

module ArticleAuditing
  module Checks
    # Flags a page with no inline citations at all (neither <ref> tags nor
    # footnote templates such as {{sfn}}), and a page whose inline citations
    # have no reference list to display them.
    class ReferenceList < Check
      KEY = 'sourcing.reference_list'
      CATEGORY = 'sourcing'

      REFERENCE_LIST = /
        \{\{\s*(?:reflist|references|refs|ref\ list|reference\ list)\s*[|}]
        | <references\b
      /ix

      def run(context)
        wikitext = context.parsed_wikitext
        return output([no_citations]) unless wikitext.inline_citations?
        return output([missing_list]) unless wikitext.without_comments.match?(REFERENCE_LIST)
        output([])
      end

      private

      def no_citations
        finding(severity: 'must_fix', **coded(:no_citations), policy_refs: %w[WP:V WP:CITE])
      end

      def missing_list
        finding(severity: 'must_fix', **coded(:missing_list),
                suggestion: "==References==\n{{Reflist}}",
                policy_refs: %w[WP:REFLIST])
      end
    end
  end
end
