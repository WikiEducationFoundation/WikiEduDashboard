# frozen_string_literal: true

module ArticleAuditing
  # Asks an LLM whether one fetched source supports each of the claims that
  # cite it. All of a source's claims go in one request (or a few, for a
  # source cited by many sentences), so the source text is paid for once
  # rather than once per claim. When a source needs more than one request,
  # its text is a cache breakpoint so the later requests read it from cache.
  class CitationJudge
    SOURCE_TEXT_LIMIT = 150_000
    CLAIMS_PER_REQUEST = 20
    VERDICTS = %w[supported partially_supported not_supported contradicted wrong_source
                  cannot_judge].freeze

    SCHEMA = {
      type: 'object',
      additionalProperties: false,
      required: %w[verdicts],
      properties: {
        verdicts: {
          type: 'array',
          items: {
            type: 'object',
            additionalProperties: false,
            required: %w[claim verdict quote explanation],
            properties: {
              claim: { type: 'integer' },
              verdict: { type: 'string', enum: VERDICTS },
              quote: { type: 'string' },
              explanation: { type: 'string' }
            }
          }
        }
      }
    }.freeze

    Judgment = Data.define(:verdicts, :usage, :truncated)

    def initialize(adapter:, prompt:, model:, effort:)
      @adapter = adapter
      @prompt = prompt
      @model = model
      @effort = effort
    end

    # +claims+ is { id => ClaimVerification::Claim }, and +citation+ the
    # citation's text as the article shows it. Returns a Judgment whose
    # verdicts are { id => { 'verdict', 'quote', 'explanation' } }.
    def judge(claims, source, citation)
      batches = claims.each_slice(CLAIMS_PER_REQUEST).to_a
      system_blocks = system_blocks(source, citation, cache: batches.size > 1)
      verdicts = {}
      usage = Hash.new(0)
      batches.each do |batch|
        response = request(system_blocks, batch.to_h)
        verdicts.merge!(verdicts_from(response.json, batch.to_h.keys))
        add_usage(usage, response.usage)
      end
      Judgment.new(verdicts:, usage:, truncated: source.text.length > SOURCE_TEXT_LIMIT)
    end

    private

    def request(system_blocks, claims)
      @adapter.complete(system_blocks:, user: claims_block(claims), json_schema: SCHEMA,
                        model: @model, effort: @effort)
    end

    def system_blocks(source, citation, cache:)
      [{ text: @prompt, cache: false },
       { text: source_block(source, citation), cache: }]
    end

    def source_block(source, citation)
      <<~SOURCE
        <citation>#{citation}</citation>
        <source url="#{CGI.escapeHTML(source.url.to_s)}">
        #{source.text[0, SOURCE_TEXT_LIMIT]}
        </source>
      SOURCE
    end

    def claims_block(claims)
      claims.map do |id, claim|
        context = claim.context == claim.sentence ? '' : "\n<context>#{claim.context}</context>"
        %(<claim id="#{id}">\n<sentence>#{claim.sentence}</sentence>#{context}\n</claim>)
      end.join("\n")
    end

    # Verdicts for the requested claim ids only, ignoring any the model made up.
    def verdicts_from(json, ids)
      Array(json&.dig('verdicts')).each_with_object({}) do |verdict, found|
        next unless ids.include?(verdict['claim']) && VERDICTS.include?(verdict['verdict'])
        found[verdict['claim']] = verdict.slice('verdict', 'quote', 'explanation')
      end
    end

    def add_usage(totals, usage)
      usage.to_h.each { |key, value| totals[key] += value if value.is_a?(Numeric) }
    end
  end
end
