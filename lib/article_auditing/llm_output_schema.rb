# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/finding"

module ArticleAuditing
  # The response schema shared by every LLM check that reads the article from
  # the prompt cache. The API puts the schema ahead of the system blocks, so
  # a check with a schema of its own can't read the cached article and writes
  # a new copy of it instead (about 40% of a new-article audit's cost before
  # this schema was shared). With one schema, an audit writes the cache once.
  #
  # Every check fills `findings`. The other properties are optional, one per
  # check that returns an artifact; each check's prompt names the property it
  # fills, and LlmCheck keeps only its own (see LlmCheck::ARTIFACTS).
  #
  # Changing anything here changes every LLM check's version.
  module LlmOutputSchema
    def self.object(properties)
      { type: 'object', additionalProperties: false, required: properties.keys.map(&:to_s),
        properties: }
    end

    def self.string_enum(values)
      { type: 'string', enum: values }
    end

    STRING = { type: 'string' }.freeze

    # sourcing.source_table
    SOURCE = object(
      source: STRING, citation: STRING,
      source_type: string_enum(%w[primary secondary tertiary unclear]),
      reliability: string_enum(%w[generally_reliable use_with_caution unreliable unclear]),
      independent: string_enum(%w[yes no unclear]),
      notes: STRING
    )

    ARTIFACTS = {
      sources: { type: 'array', items: SOURCE },
      # new_article.notability
      notability: object(
        assessment: string_enum(%w[likely_notable unclear unlikely_notable]),
        guideline: STRING, rationale: STRING
      ),
      # new_article.short_description
      short_description: object(current: STRING, proposed: STRING),
      # new_article.existing_coverage
      coverage: object(
        verdict: string_enum(%w[not_covered partially_covered already_covered]),
        related: { type: 'array', items: object(title: STRING, relationship: STRING) }
      ),
      # new_article.categories
      categories: { type: 'array', items: object(name: STRING, reason: STRING) }
    }.freeze

    SCHEMA = {
      type: 'object',
      additionalProperties: false,
      required: %w[findings],
      properties: { findings: { type: 'array', items: Finding::LLM_SCHEMA } }.merge(ARTIFACTS)
    }.freeze
  end
end
