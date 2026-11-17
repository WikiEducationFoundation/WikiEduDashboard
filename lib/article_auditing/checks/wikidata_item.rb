# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/check"

module ArticleAuditing
  module Checks
    # Wikidata: an existing article with no Wikidata item, and for a new
    # article, items that might be its subject. An item already linked to a
    # different English Wikipedia article suggests the topic is already
    # covered under another title.
    class WikidataItem < Check
      KEY = 'new_article.wikidata'
      CATEGORY = 'new_article'

      def applies_to?(context)
        context.wiki_context.target_title.present?
      end

      def run(context)
        wiki_context = context.wiki_context
        return existing_article_output(wiki_context) if wiki_context.target_exists?
        candidates_output(wiki_context.wikidata_candidates(wiki_context.target_title))
      end

      private

      def existing_article_output(wiki_context)
        return output([]) if wiki_context.target_page[:wikibase_item]
        output([finding(severity: 'suggestion', **coded(:no_item), policy_refs: %w[WP:WIKIDATA])])
      end

      def candidates_output(candidates)
        linked, unlinked = candidates.partition { |item| item[:enwiki] }
        findings = linked.map do |item|
          problem = coded(:item_has_article, id: item[:id], article: item[:enwiki])
          finding(severity: 'info', **problem, policy_refs: %w[WP:DUPLICATE])
        end
        if unlinked.any?
          findings << finding(severity: 'info', **coded(:possible_item, count: unlinked.size),
                              policy_refs: %w[WP:WIKIDATA])
        end
        output(findings, artifacts: { 'wikidata_candidates' => candidates.map(&:stringify_keys) })
      end
    end
  end
end
