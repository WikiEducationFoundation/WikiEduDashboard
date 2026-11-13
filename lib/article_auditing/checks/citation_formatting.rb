# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/llm_check"

module ArticleAuditing
  module Checks
    # Citation formatting: bare URLs, missing fields, inconsistent styles.
    # Prompt: config/article_audit/prompts/sourcing.citation_formatting.md
    class CitationFormatting < LlmCheck
      KEY = 'sourcing.citation_formatting'
      CATEGORY = 'sourcing'
    end
  end
end
