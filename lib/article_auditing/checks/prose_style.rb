# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/llm_check"

module ArticleAuditing
  module Checks
    # Manual of Style issues in the prose: numbers, spelling consistency, headings, italics.
    # Prompt: config/article_audit/prompts/mos.prose.md
    class ProseStyle < LlmCheck
      KEY = 'mos.prose'
      CATEGORY = 'mos'
    end
  end
end
