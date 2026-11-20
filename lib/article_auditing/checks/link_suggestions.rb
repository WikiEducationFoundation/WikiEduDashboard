# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/llm_check"

module ArticleAuditing
  module Checks
    # Terms that should be wikilinked, and common terms that shouldn't be (MOS:OVERLINK).
    # Prompt: config/article_audit/prompts/links.suggestions.md
    class LinkSuggestions < LlmCheck
      KEY = 'links.suggestions'
      CATEGORY = 'links'
    end
  end
end
