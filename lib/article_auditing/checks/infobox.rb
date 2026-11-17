# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/llm_check"

module ArticleAuditing
  module Checks
    # Infobox choice, important parameters, and mismatches with the article text.
    # Prompt: config/article_audit/prompts/infobox.md
    class Infobox < LlmCheck
      KEY = 'infobox'
      CATEGORY = 'infobox'
    end
  end
end
