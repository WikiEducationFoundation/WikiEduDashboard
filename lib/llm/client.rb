# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/llm/anthropic_adapter"

module Llm
  # Provider-agnostic entry point for LLM completions. Services use
  # this seam so that switching providers — including self-hosted open
  # models behind an OpenAI-compatible endpoint, as a future adapter —
  # is a configuration change, not a code change.
  #
  #   Llm::Client.adapter.complete(system: '...', user: '...',
  #                                json_schema: { ... })
  #
  # Every adapter implements `complete(system:, user:, json_schema:)`
  # and returns an Llm::Response.
  class Client
    ADAPTERS = {
      'anthropic' => AnthropicAdapter
    }.freeze

    def self.adapter
      provider = ENV['llm_provider'] || 'anthropic'
      adapter_class = ADAPTERS[provider]
      raise UnknownProviderError, "no LLM adapter for provider '#{provider}'" if adapter_class.nil?
      adapter_class.new
    end

    class UnknownProviderError < StandardError; end
  end
end
