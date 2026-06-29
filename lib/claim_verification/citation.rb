# frozen_string_literal: true

module ClaimVerification
  # One entry from a revision's reference list.
  # - ref_id: the reference-list id, eg 'cite_note-Smith-1'
  # - cite_html: the inner HTML of the <cite> element (or the full
  #   reference text when there is no <cite>)
  # - cite_text: plain text of the reference
  # - urls: external source URLs from the reference
  # - archive_urls: web.archive.org URLs, kept separate so a fetcher
  #   can fall back to them when the primary URL is inaccessible
  # - unresolved: true when the ref was invoked but not defined in this
  #   render (a named ref defined elsewhere) — it renders as a cite error
  Citation = Data.define(:ref_id, :cite_html, :cite_text, :urls, :archive_urls,
                         :unresolved) do
    # `unresolved` defaults to false so callers that don't track resolution
    # state (eg source fetching) can construct a Citation without it.
    def initialize(unresolved: false, **rest)
      super(unresolved:, **rest)
    end

    # The MediaWiki named-ref name embedded in a cite_note id, eg
    # 'cite_note-:3-1' -> ':3', 'cite_note-Smith-2' -> 'Smith'. The trailing
    # number differs between renders, so matching on the name links a citation
    # resolved in one render (eg the full revision) to the same ref in another
    # (eg a diff). An unnamed ref ('cite_note-5') yields the bare number, which
    # won't match across renders — fine, unnamed refs are defined inline.
    def self.ref_name(ref_id)
      ref_id.to_s.sub(/\Acite_note-/, '').sub(/-\d+\z/, '')
    end

    def ref_name
      self.class.ref_name(ref_id)
    end

    def unresolved?
      unresolved
    end

    def offline_source?
      urls.empty? && archive_urls.empty?
    end
  end
end
