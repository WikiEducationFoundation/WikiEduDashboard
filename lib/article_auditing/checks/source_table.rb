# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/llm_check"

module ArticleAuditing
  module Checks
    # Assesses each cited source's type, reliability and independence from the
    # subject, returning the assessments as a table, with findings for the
    # sources that are a problem.
    # Prompt: config/article_audit/prompts/sourcing.source_table.md
    class SourceTable < LlmCheck
      KEY = 'sourcing.source_table'
      CATEGORY = 'sourcing'
      ARTIFACTS = %w[sources].freeze
    end
  end
end
