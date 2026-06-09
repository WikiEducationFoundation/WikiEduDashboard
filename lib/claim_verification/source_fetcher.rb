# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/claim_verification/fetched_source"

module ClaimVerification
  # Retrieves the readable text of a citation's source so a claim can
  # be checked against it. Tries the citation's source URLs first, then
  # archive URLs. Sources without any URL (books, offline journals) and
  # URLs that cannot be retrieved or are not HTML (PDFs, paywalls
  # returning errors) are classified rather than raised, since
  # inaccessible sources are a first-class outcome for verification.
  class SourceFetcher
    OPEN_TIMEOUT = 15
    REQUEST_TIMEOUT = 30
    MAX_REDIRECTS = 5
    REDIRECT_STATUSES = [301, 302, 303, 307, 308].freeze

    attr_reader :result

    def initialize(citation)
      @citation = citation
      @result = fetch
    end

    private

    def fetch
      return offline_result if @citation.offline_source?

      failures = []
      candidate_urls.each do |url|
        outcome = try_url(url)
        return outcome if outcome.fetched?
        failures << "#{url}: #{outcome.reason}"
      end
      FetchedSource.new(status: :inaccessible, text: nil,
                        url: candidate_urls.first, reason: failures.join('; '))
    end

    def offline_result
      FetchedSource.new(status: :offline_source, text: nil, url: nil,
                        reason: 'citation has no source URL')
    end

    def candidate_urls
      @citation.urls + @citation.archive_urls
    end

    def try_url(url)
      response = get_following_redirects(url)
      return failure(url, "HTTP #{response.status}") unless response.status == 200
      return failure(url, "unsupported content type #{content_type(response)}") unless
        html?(response)
      FetchedSource.new(status: :fetched, text: readable_text(response.body),
                        url:, reason: nil)
    rescue Faraday::Error, URI::Error, TooManyRedirectsError => e
      failure(url, e.class.name.demodulize)
    end

    def failure(url, reason)
      FetchedSource.new(status: :inaccessible, text: nil, url:, reason:)
    end

    def get_following_redirects(url)
      MAX_REDIRECTS.times do
        response = connection(url).get
        return response unless REDIRECT_STATUSES.include?(response.status)
        url = URI.join(url, response.headers['location']).to_s
      end
      raise TooManyRedirectsError
    end

    def connection(url)
      Faraday.new(
        url:,
        headers: { 'User-Agent' => "#{ENV.fetch('dashboard_url', '')} #{Rails.env}".strip },
        request: { open_timeout: OPEN_TIMEOUT, timeout: REQUEST_TIMEOUT }
      )
    end

    def content_type(response)
      response.headers['content-type'].to_s
    end

    def html?(response)
      type = content_type(response)
      type.empty? || type.include?('html') || type.include?('text/plain')
    end

    def readable_text(html)
      doc = Nokogiri::HTML(html)
      doc.css('script, style, nav, header, footer, aside, noscript, form, iframe')
         .each(&:remove)
      text = (doc.at_css('body') || doc).text
      text.gsub(/[ \t]+/, ' ').gsub(/\s*\n\s*/, "\n").squeeze("\n").strip
    end

    class TooManyRedirectsError < StandardError; end
  end
end
