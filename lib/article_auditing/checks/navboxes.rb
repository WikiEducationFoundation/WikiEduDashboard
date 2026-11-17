# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/check"

module ArticleAuditing
  module Checks
    # Navigation boxes that already link to the article but aren't placed on
    # it (WP:NAVBOX: a navbox normally appears on every article it links to).
    class Navboxes < Check
      KEY = 'links.navboxes'
      CATEGORY = 'links'
      MAX_FINDINGS = 5

      def applies_to?(context)
        context.wiki_context.target_title.present?
      end

      def run(context)
        placed = placed_templates(context)
        missing = context.wiki_context.navboxes_linking_target.reject do |template|
          placed.include?(template_name(template).downcase)
        end
        findings = missing.first(MAX_FINDINGS).map do |template|
          name = template_name(template)
          finding(severity: 'suggestion', **coded(:missing_navbox, navbox: name),
                  suggestion: "{{#{name}}}", policy_refs: %w[WP:NAVBOX WP:BIDIRECTIONAL])
        end
        output(findings)
      end

      private

      # Templates on the audited page and, for a draft, on the target article.
      def placed_templates(context)
        on_page = context.parsed_wikitext.templates(/./).map do |_, text|
          text[2..].split(/[|}]/, 2).first.to_s.strip.tr('_', ' ').downcase
        end
        on_target = Array(context.wiki_context.target_page&.dig(:templates)).map do |title|
          template_name(title).downcase
        end
        (on_page + on_target).to_set
      end

      def template_name(title)
        title.delete_prefix('Template:')
      end
    end
  end
end
