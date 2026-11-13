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

      SOURCE_SCHEMA = {
        type: 'object',
        additionalProperties: false,
        required: %w[source citation source_type reliability independent notes],
        properties: {
          source: { type: 'string' },
          citation: { type: 'string' },
          source_type: { type: 'string', enum: %w[primary secondary tertiary unclear] },
          reliability: { type: 'string',
                         enum: %w[generally_reliable use_with_caution unreliable unclear] },
          independent: { type: 'string', enum: %w[yes no unclear] },
          notes: { type: 'string' }
        }
      }.freeze

      private

      def artifact_properties
        { sources: { type: 'array', items: SOURCE_SCHEMA } }
      end
    end
  end
end
