# frozen_string_literal: true

module Llm
  # Normalized completion result, independent of which provider
  # produced it.
  # - text: the completion text
  # - json: parsed Hash when a json_schema was requested, else nil
  # - model: the model that produced the completion
  # - usage: { input_tokens:, output_tokens: } for cost tracking
  Response = Data.define(:text, :json, :model, :usage)
end
