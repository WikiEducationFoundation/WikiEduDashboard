# frozen_string_literal: true

require 'anthropic'
require_dependency "#{Rails.root}/lib/llm/response"
require_dependency "#{Rails.root}/lib/llm/errors"

module Llm
  # Adapter for the Claude API via the official `anthropic` gem.
  # Transport and structured-output mechanics only — prompts live with the
  # calling code, never here.
  #
  # system_blocks is an array of { text:, cache: } hashes. A block with
  # cache: true gets a prompt-cache breakpoint, so callers that send the same
  # long prefix (eg an article) with different instructions pay for it once.
  class AnthropicAdapter
    DEFAULT_MODEL = 'claude-opus-5-5'
    MAX_TOKENS = 16_000
    # Server-side refusal fallback: if the requested model declines for policy
    # reasons, the API re-runs the request on a server-chosen fallback model.
    FALLBACK_BETA = 'server-side-fallback-2026-07-01'

    # The SDK retries rate limits, overload and 5xx errors this many times,
    # with backoff, before giving up.
    def initialize(max_retries: 2)
      @max_retries = max_retries
    end

    def complete(system_blocks:, user:, json_schema: nil, model: nil, effort: nil)
      message = create_message(request_params(system_blocks:, user:, json_schema:, model:, effort:))
      check_stop_reason(message)
      text = text_content(message)
      Response.new(text:,
                   json: json_schema ? parse_json(text) : nil,
                   model: message.model.to_s,
                   usage: usage_hash(message))
    end

    private

    def request_params(system_blocks:, user:, json_schema:, model:, effort:)
      output_config = {}
      output_config[:effort] = effort.to_sym if effort
      output_config[:format] = { type: :json_schema, schema: json_schema } if json_schema
      params = {
        model: (model || DEFAULT_MODEL).to_sym,
        max_tokens: MAX_TOKENS,
        system_: system_blocks.map { |block| system_block(block) },
        messages: [{ role: :user, content: user }],
        betas: [FALLBACK_BETA],
        fallbacks: :default
      }
      params[:output_config] = output_config if output_config.any?
      params
    end

    def system_block(block)
      param = { type: :text, text: block[:text] }
      param[:cache_control] = { type: :ephemeral } if block[:cache]
      param
    end

    # The SDK already retries 408/409/429/5xx and connection errors a couple
    # of times; whatever still fails is translated into an Llm::Error.
    def create_message(params)
      client.beta.messages.create(**params)
    rescue Anthropic::Errors::RateLimitError,
           Anthropic::Errors::InternalServerError,
           Anthropic::Errors::APIConnectionError => e
      raise RetryableError, e.message
    rescue Anthropic::Errors::APIStatusError => e
      raise RequestError, "#{e.status}: #{e.message}"
    end

    def check_stop_reason(message)
      case message.stop_reason&.to_sym
      when :refusal
        details = message.stop_details
        raise RefusalError, "refused (#{details&.category || 'uncategorized'}): " \
                            "#{details&.explanation}"
      when :max_tokens
        raise IncompleteResponseError, 'response truncated at max_tokens'
      end
    end

    def text_content(message)
      text = message.content.find { |block| block.type.to_sym == :text }&.text
      raise IncompleteResponseError, 'response had no text content' if text.blank?
      text
    end

    def parse_json(text)
      JSON.parse(text)
    rescue JSON::ParserError => e
      raise IncompleteResponseError, "structured output was not valid JSON: #{e.message}"
    end

    def usage_hash(message)
      usage = message.usage
      { 'input_tokens' => usage.input_tokens,
        'output_tokens' => usage.output_tokens,
        'cache_creation_input_tokens' => usage.cache_creation_input_tokens || 0,
        'cache_read_input_tokens' => usage.cache_read_input_tokens || 0,
        'message_id' => message.id }
    end

    def client
      @client ||= Anthropic::Client.new(api_key: ENV['anthropic_api_key'],
                                        max_retries: @max_retries)
    end
  end
end
