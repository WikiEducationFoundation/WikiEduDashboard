# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/llm_check"

module ArticleAuditing
  module Checks
    # Whether the lead summarizes the article, bolds the title and establishes notability.
    # Prompt: config/article_audit/prompts/structure.lead.md
    class LeadContent < LlmCheck
      KEY = 'structure.lead'
      CATEGORY = 'structure'
    end
  end
end
