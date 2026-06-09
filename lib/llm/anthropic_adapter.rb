# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/llm/response"

module Llm
  # Adapter for the Claude API via the official `anthropic` gem.
  # Transport and structured-output mechanics only — prompts live with
  # the calling services, never here.
  class AnthropicAdapter
    DEFAULT_MODEL = 'claude-opus-4-8'
    MAX_TOKENS = 16_000

    def complete(system:, user:, json_schema: nil)
      message = client.messages.create(**request_params(system, user, json_schema))
      text = text_content(message)
      Response.new(text:,
                   json: json_schema ? JSON.parse(text) : nil,
                   model: message.model.to_s,
                   usage: { input_tokens: message.usage.input_tokens,
                            output_tokens: message.usage.output_tokens })
    end

    private

    def request_params(system, user, json_schema)
      params = {
        model: ENV['llm_model'] || DEFAULT_MODEL,
        max_tokens: MAX_TOKENS,
        system:,
        messages: [{ role: 'user', content: user }]
      }
      if json_schema
        params[:output_config] = { format: { type: 'json_schema', schema: json_schema } }
      end
      params
    end

    def text_content(message)
      message.content.find { |block| block.type.to_sym == :text }&.text
    end

    def client
      @client ||= Anthropic::Client.new(api_key: ENV['anthropic_api_key'])
    end
  end
end
