# frozen_string_literal: true

module ClaimVerification
  # The outcome of checking one claim against one source.
  # - verdict: one of VERDICTS
  # - quote: the passage from the source that supports or contradicts
  #   the claim, so verdicts are human-auditable
  # - explanation: short rationale
  # - model/usage: passthrough from the LLM call for cost tracking
  # - source_truncated: true when the source text exceeded the size cap
  #   and the judge saw only the beginning of it
  Verdict = Data.define(:verdict, :quote, :explanation, :model, :usage,
                        :source_truncated) do
    VERDICTS = %w[supported partially_supported not_supported
                  contradicted source_inaccessible].freeze
  end
end
