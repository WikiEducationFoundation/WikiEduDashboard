# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/llm_check"

module ArticleAuditing
  module Checks
    # Proposes a short description (WP:SHORTDESC) for a new article or an
    # article without one, and reviews an existing one.
    # Prompt: config/article_audit/prompts/new_article.short_description.md
    class ShortDescription < LlmCheck
      KEY = 'new_article.short_description'
      CATEGORY = 'new_article'
      ARTIFACTS = %w[short_description].freeze

      SHORT_DESCRIPTION = /\{\{\s*short description\s*\|/i

      def applies_to?(context)
        return true if context.new_article?
        context.mainspace? && !context.wikitext.match?(SHORT_DESCRIPTION)
      end
    end
  end
end
