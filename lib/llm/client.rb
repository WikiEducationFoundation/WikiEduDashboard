# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/llm/anthropic_adapter"

module Llm
  # Provider-agnostic entry point for LLM completions. Callers pick an
  # adapter by provider name, so that adding another provider — such as
  # self-hosted open-weight models behind an OpenAI-compatible endpoint —
  # means adding an adapter class here, not changing callers.
  #
  #   Llm::Client.adapter('anthropic').complete(
  #     system_blocks: [{ text: '...', cache: true }], user: '...',
  #     json_schema: { ... }, model: 'claude-opus-5-5', effort: 'medium'
  #   )
  #
  # Every adapter implements that `complete` signature and returns an
  # Llm::Response, raising only Llm::Error subclasses.
  class Client
    ADAPTERS = {
      'anthropic' => AnthropicAdapter
    }.freeze

    def self.adapter(provider = 'anthropic')
      adapter_class = ADAPTERS[provider]
      raise UnknownProviderError, "no LLM adapter for provider '#{provider}'" if adapter_class.nil?
      adapter_class.new
    end

    class UnknownProviderError < StandardError; end
  end
end
