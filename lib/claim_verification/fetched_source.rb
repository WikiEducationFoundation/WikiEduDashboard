# frozen_string_literal: true

module ClaimVerification
  # The outcome of trying to retrieve a cited source's text.
  # - status: :fetched | :inaccessible | :offline_source
  # - text: readable text of the source (only when fetched)
  # - url: the URL the text came from, or the first URL tried
  # - reason: why the source could not be fetched
  FetchedSource = Data.define(:status, :text, :url, :reason) do
    def fetched?
      status == :fetched
    end
  end
end
