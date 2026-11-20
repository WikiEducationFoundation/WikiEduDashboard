# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/llm_check"

module ArticleAuditing
  module Checks
    # Promotional language, weasel words, editorializing, balance, and
    # analysis presented in Wikipedia's voice.
    # Prompt: config/article_audit/prompts/tone.md
    class Tone < LlmCheck
      KEY = 'tone'
      CATEGORY = 'tone'
    end
  end
end
