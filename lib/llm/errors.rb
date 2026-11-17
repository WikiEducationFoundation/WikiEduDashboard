# frozen_string_literal: true

module Llm
  # Base class for provider-independent LLM failures. Adapters translate
  # their SDK's exceptions into these so callers never rescue SDK classes.
  class Error < StandardError; end

  # Transient: rate limits, overload, 5xx, network. Worth retrying later.
  class RetryableError < Error; end

  # Terminal: the request itself was rejected (bad params, auth, too large).
  class RequestError < Error; end

  # The model declined the request for policy reasons, even after any
  # configured fallback models.
  class RefusalError < Error; end

  # The completion hit max_tokens or otherwise produced no usable output.
  class IncompleteResponseError < Error; end
end
