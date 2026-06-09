# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/claim_verification/verdict"
require_dependency "#{Rails.root}/lib/llm/client"

# Judges whether one claim is supported by the text of its cited
# source, via a single LLM call with a JSON-schema-constrained output.
# When the source could not be fetched (source_status other than
# :fetched), short-circuits to a source_inaccessible verdict without
# calling the LLM — inaccessible sources are a first-class outcome.
class VerifyClaimAgainstSource
  attr_reader :verdict

  # Keeps the judge prompt well inside context limits; longer sources
  # are truncated with the source_truncated flag recorded on the
  # verdict. Chunked retrieval for long sources is a later component.
  SOURCE_TEXT_CHARACTER_LIMIT = 150_000

  JUDGE_SYSTEM_PROMPT = <<~PROMPT
    You verify whether factual claims from Wikipedia articles are
    supported by the text of the source cited for them. Judge only
    from the source text provided; do not use outside knowledge to
    fill gaps. Verdicts:
    - supported: the source asserts the claim (directly or by clear
      paraphrase)
    - partially_supported: the source asserts part of the claim, but
      part of it is absent or only weakly implied
    - not_supported: the source does not address the claim
    - contradicted: the source asserts the opposite of the claim
    Quote the passage from the source that most directly supports or
    contradicts the claim; leave the quote empty for not_supported.
  PROMPT

  JUDGE_SCHEMA = {
    type: 'object',
    properties: {
      verdict: {
        type: 'string',
        enum: %w[supported partially_supported not_supported contradicted]
      },
      quote: { type: 'string' },
      explanation: { type: 'string' }
    },
    required: %w[verdict quote explanation],
    additionalProperties: false
  }.freeze

  # claim: ClaimVerification::Claim (or anything responding to
  # #sentence and #context) or a plain string.
  def initialize(claim:, source_text:, source_status: :fetched)
    @claim = claim
    @source_text = source_text
    @source_status = source_status
    perform
  end

  private

  def perform
    return inaccessible_verdict unless @source_status == :fetched
    judge
  end

  def inaccessible_verdict
    @verdict = ClaimVerification::Verdict.new(
      verdict: 'source_inaccessible', quote: nil,
      explanation: "source not fetched: #{@source_status}",
      model: nil, usage: nil, source_truncated: false
    )
  end

  def judge
    response = Llm::Client.adapter.complete(system: JUDGE_SYSTEM_PROMPT,
                                            user: judge_prompt,
                                            json_schema: JUDGE_SCHEMA)
    @verdict = ClaimVerification::Verdict.new(
      verdict: response.json['verdict'], quote: response.json['quote'],
      explanation: response.json['explanation'],
      model: response.model, usage: response.usage,
      source_truncated: truncated?
    )
  end

  def judge_prompt
    <<~PROMPT
      Claim:
      #{claim_sentence}
      #{claim_context_section}
      Source text:
      #{truncated_source_text}
    PROMPT
  end

  def claim_sentence
    @claim.respond_to?(:sentence) ? @claim.sentence : @claim.to_s
  end

  def claim_context_section
    return '' unless @claim.respond_to?(:context) && @claim.context.present?
    return '' if @claim.context == claim_sentence

    "\nParagraph context for the claim:\n#{@claim.context}\n"
  end

  def truncated?
    @source_text.length > SOURCE_TEXT_CHARACTER_LIMIT
  end

  def truncated_source_text
    @source_text[0, SOURCE_TEXT_CHARACTER_LIMIT]
  end
end
