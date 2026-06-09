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
  Citation = Data.define(:ref_id, :cite_html, :cite_text, :urls, :archive_urls) do
    def offline_source?
      urls.empty? && archive_urls.empty?
    end
  end
end
