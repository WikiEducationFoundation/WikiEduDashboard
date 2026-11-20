# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/llm_check"

module ArticleAuditing
  module Checks
    # Section structure and weight for the type of article (MEDMOS, NOTCV, SUMMARY...).
    # Prompt: config/article_audit/prompts/structure.sections.md
    class SectionStructure < LlmCheck
      KEY = 'structure.sections'
      CATEGORY = 'structure'
    end
  end
end
