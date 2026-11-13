# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/llm_check"

module ArticleAuditing
  module Checks
    # Proposes a short description (WP:SHORTDESC) for a draft, a new article,
    # or an article without one, and reviews an existing one.
    # Prompt: config/article_audit/prompts/new_article.short_description.md
    class ShortDescription < LlmCheck
      KEY = 'new_article.short_description'
      CATEGORY = 'new_article'

      SHORT_DESCRIPTION = /\{\{\s*short description\s*\|/i

      def applies_to?(context)
        !context.mainspace? || context.page_creation? ||
          !context.wikitext.match?(SHORT_DESCRIPTION)
      end

      private

      def artifact_properties
        {
          short_description: {
            type: 'object',
            additionalProperties: false,
            required: %w[current proposed],
            properties: { current: { type: 'string' }, proposed: { type: 'string' } }
          }
        }
      end
    end
  end
end
