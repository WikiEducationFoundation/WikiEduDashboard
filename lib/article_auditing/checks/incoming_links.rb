# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/check"

module ArticleAuditing
  module Checks
    # Whether readers can reach the article: an existing article with few or
    # no links from other articles (WP:ORPHAN), and articles that mention the
    # topic without linking to it, where a link could be added.
    class IncomingLinks < Check
      KEY = 'links.incoming_links'
      CATEGORY = 'links'
      FEW_LINKS = 3

      def applies_to?(context)
        context.wiki_context.target_title.present?
      end

      def run(context)
        wiki_context = context.wiki_context
        mentions = wiki_context.unlinked_mentions
        findings = []
        findings << few_links_finding(wiki_context) if few_links?(wiki_context)
        # Mentions matter for a new or poorly linked article; for a
        # well-linked one they are only kept as an artifact.
        if mentions.any? && (findings.any? || context.new_article?)
          findings << mentions_finding(mentions)
        end
        output(findings, artifacts: { 'unlinked_mentions' => mentions.map(&:stringify_keys) })
      end

      private

      def few_links?(wiki_context)
        wiki_context.target_exists? && wiki_context.incoming_link_count < FEW_LINKS
      end

      def few_links_finding(wiki_context)
        count = wiki_context.incoming_link_count
        finding(severity: count.zero? ? 'should_fix' : 'suggestion', **coded(:few_links, count:),
                policy_refs: %w[WP:ORPHAN])
      end

      def mentions_finding(mentions)
        examples = mentions.first(3).pluck(:title).join(', ')
        finding(severity: 'suggestion',
                **coded(:unlinked_mentions, count: mentions.size, examples:),
                policy_refs: %w[WP:BUILD])
      end
    end
  end
end
