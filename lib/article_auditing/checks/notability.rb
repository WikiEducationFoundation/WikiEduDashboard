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
      ARTIFACTS = %w[notability].freeze

      def applies_to?(context)
        context.new_article?
      end
    end
  end
end
