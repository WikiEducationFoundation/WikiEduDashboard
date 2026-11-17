# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/llm_check"

module ArticleAuditing
  module Checks
    # Content policy problems: BLP, original research, COI signals, MEDRS, NOT.
    # Prompt: config/article_audit/prompts/policy.md
    class PolicyCheck < LlmCheck
      KEY = 'policy'
      CATEGORY = 'policy'
    end
  end
end
