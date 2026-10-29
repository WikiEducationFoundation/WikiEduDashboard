# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/claim_library/source_kind"

module ClaimLibrary
  # A cited source as it was read for the library.
  # - url: the citation's own URL
  # - read_from: the copy the text was taken from (the live page, an archive
  #   snapshot or a full-text service), or nil when none could be read
  # - kind: a rough classification of the URL (see SourceKind), shown to the
  #   annotator as a hint about who is speaking, never used to judge
  # - status: 'read' or 'unreadable'
  # - text: the plain text, held in memory only; the library file keeps the
  #   provenance and the cache keeps the text
  Source = Data.define(:url, :read_from, :kind, :status, :text, :fetched_at, :error) do
    def self.read(url:, read_from:, text:)
      new(url:, read_from:, kind: SourceKind.of(url), status: 'read', text:,
          fetched_at: Time.zone.now, error: nil)
    end

    def self.unreadable(url, error)
      new(url:, read_from: nil, kind: SourceKind.of(url), status: 'unreadable', text: nil,
          fetched_at: Time.zone.now, error:)
    end

    def self.from_h(hash)
      return if hash.nil?
      hash = hash.transform_keys(&:to_s)
      new(url: hash['url'], read_from: hash['read_from'], kind: hash['kind'],
          status: hash['status'], text: hash['text'],
          fetched_at: hash['fetched_at'] && Time.zone.parse(hash['fetched_at']),
          error: hash['error'])
    end

    def readable?
      status == 'read'
    end

    # Everything but the text, for the library file and the cache.
    def provenance
      { 'url' => url, 'read_from' => read_from, 'kind' => kind, 'status' => status,
        'fetched_at' => fetched_at&.iso8601, 'error' => error }
    end
  end
end
