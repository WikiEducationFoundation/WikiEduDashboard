# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/claim_verification/claim_citation_extractor"
require_dependency "#{Rails.root}/lib/llm/client"

# Extracts cited claims and their citations from revision HTML.
# In the default :structural mode this is a free, deterministic pass
# through ClaimVerification::ClaimCitationExtractor — one claim per
# cited sentence. In :llm mode, each cited sentence is additionally
# decomposed into atomic factual claims (one sentence often bundles
# several independently checkable facts), each still linked to the
# sentence's citations.
class ExtractClaimsAndSources
  attr_reader :claims, :citations, :paragraphs, :usage

  DECOMPOSITION_SYSTEM_PROMPT = <<~PROMPT
    You decompose sentences from Wikipedia articles into atomic factual
    claims. Each atomic claim must be a single, independently checkable
    factual statement, understandable on its own without the original
    sentence. Resolve pronouns and other references using the provided
    paragraph context. Do not add facts that are not asserted by the
    sentence. If the sentence asserts only one fact, return it as a
    single claim.
  PROMPT

  DECOMPOSITION_SCHEMA = {
    type: 'object',
    properties: {
      claims: { type: 'array', items: { type: 'string' } }
    },
    required: ['claims'],
    additionalProperties: false
  }.freeze

  def initialize(html, mode: :structural)
    @html = html
    @mode = mode
    @usage = []
    perform
  end

  private

  def perform
    extractor = ClaimVerification::ClaimCitationExtractor.new(@html)
    @citations = extractor.citations
    @claims = extractor.claims
    @paragraphs = extractor.paragraphs
    decompose_claims if @mode == :llm
  end

  def decompose_claims
    adapter = Llm::Client.adapter
    @claims = @claims.flat_map { |claim| atomic_claims(adapter, claim) }
  end

  def atomic_claims(adapter, claim)
    response = adapter.complete(system: DECOMPOSITION_SYSTEM_PROMPT,
                                user: decomposition_prompt(claim),
                                json_schema: DECOMPOSITION_SCHEMA)
    @usage << response.usage
    response.json['claims'].map do |atomic_sentence|
      ClaimVerification::Claim.new(sentence: atomic_sentence,
                                   ref_ids: claim.ref_ids,
                                   context: claim.context)
    end
  end

  def decomposition_prompt(claim)
    <<~PROMPT
      Paragraph context:
      #{claim.context}

      Sentence to decompose:
      #{claim.sentence}
    PROMPT
  end
end
