# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/llm_check"

module ArticleAuditing
  module Checks
    # For a new article (not a draft improving an existing one): whether the
    # sources cited establish the topic's notability.
    # Prompt: config/article_audit/prompts/new_article.notability.md
    class Notability < LlmCheck
      KEY = 'new_article.notability'
      CATEGORY = 'new_article'

      def applies_to?(context)
        context.new_article?
      end

      private

      def artifact_properties
        {
          notability: {
            type: 'object',
            additionalProperties: false,
            required: %w[assessment guideline rationale],
            properties: {
              assessment: { type: 'string', enum: %w[likely_notable unclear unlikely_notable] },
              guideline: { type: 'string' },
              rationale: { type: 'string' }
            }
          }
        }
      end
    end
  end
end
