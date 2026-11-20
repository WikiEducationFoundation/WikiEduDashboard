# frozen_string_literal: true

module ArticleAuditing
  # The shared shape of a single audit finding, produced by every check no
  # matter which engine runs it. Findings are stored as plain Hashes (string
  # keys) on ArticleAuditCheckResult#findings.
  module Finding
    CATEGORIES = %w[
      flags sourcing tone structure mos infobox links policy new_article external
    ].freeze
    # Ordered most to least serious.
    SEVERITIES = %w[must_fix should_fix suggestion info].freeze

    # JSON schema for the findings an LLM check returns. The location and
    # suggestion fields are required but may be empty strings, which keeps the
    # schema simple for structured output; .build turns blanks into nil.
    LLM_SCHEMA = {
      type: 'object',
      additionalProperties: false,
      required: %w[severity title explanation section quote suggestion policy_refs],
      properties: {
        severity: { type: 'string', enum: SEVERITIES },
        title: { type: 'string' },
        explanation: { type: 'string' },
        section: { type: 'string' },
        quote: { type: 'string' },
        suggestion: { type: 'string' },
        policy_refs: { type: 'array', items: { type: 'string' } }
      }
    }.freeze

    module_function

    # LLM findings have a title and explanation. Findings from code have a
    # +code+ naming the problem instead, with any specifics (counts, names) in
    # +details+, so they need no written copy.
    def build(check:, category:, severity:, title: nil, explanation: nil, code: nil,
              details: {}, section: nil, quote: nil, suggestion: nil, policy_refs: [])
      severity = SEVERITIES.include?(severity) ? severity : 'suggestion'
      {
        'check' => check,
        'category' => category,
        'severity' => severity,
        'title' => title.to_s.strip,
        'explanation' => explanation.to_s.strip,
        'code' => code&.to_s,
        'details' => details.to_h.transform_keys(&:to_s).compact_blank.presence,
        'location' => { 'section' => section.presence, 'quote' => quote.presence },
        'suggestion' => suggestion.presence,
        'policy_refs' => Array(policy_refs).compact_blank
      }
    end
  end
end
