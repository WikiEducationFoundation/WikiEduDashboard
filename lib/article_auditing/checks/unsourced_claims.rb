# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/llm_check"

module ArticleAuditing
  module Checks
    # Statements that need a citation and don't have one (WP:V).
    # Prompt: config/article_audit/prompts/sourcing.unsourced_claims.md
    class UnsourcedClaims < LlmCheck
      KEY = 'sourcing.unsourced_claims'
      CATEGORY = 'sourcing'
    end
  end
end
