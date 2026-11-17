# frozen_string_literal: true

require 'resolv'
require 'ipaddr'
require_dependency "#{Rails.root}/lib/claim_verification/fetched_source"
require_dependency "#{Rails.root}/lib/claim_verification/host_throttle"

module ClaimVerification
  # Retrieves the readable text of a citation's source so a claim can
  # be checked against it. Tries the citation's source URLs first, then
  # archive URLs. Sources without any URL (books, offline journals) and
  # URLs that cannot be retrieved or are not HTML (PDFs, paywalls
  # returning errors) are classified rather than raised, since
  # inaccessible sources are a first-class outcome for verification.
  #
  # The URLs come from article content, which anyone can write, so only
  # http(s) URLs on public addresses are fetched, checked again at each
  # redirect. (This doesn't stop a DNS answer that changes between the check
  # and the request.)
  class SourceFetcher
    OPEN_TIMEOUT = 10
    REQUEST_TIMEOUT = 20
    MAX_REDIRECTS = 5
    REDIRECT_STATUSES = [301, 302, 303, 307, 308].freeze
    # Less readable text than this is a page that builds its content with
    # JavaScript, or an empty shell, rather than the cited work.
    MIN_TEXT_LENGTH = 200

    attr_reader :result

    # +throttle+ spaces out requests to the same host; share one across the
    # citations of an article, since many may point to one publisher.
    def initialize(citation, throttle: HostThrottle.new)
      @citation = citation
      @throttle = throttle
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
      text = readable_text(response.body)
      return failure(url, 'no readable text') if text.length < MIN_TEXT_LENGTH
      FetchedSource.new(status: :fetched, text:, url:, reason: nil)
    rescue Faraday::Error, URI::Error, TooManyRedirectsError, DisallowedUrlError => e
      failure(url, e.class.name.demodulize)
    end

    def failure(url, reason)
      FetchedSource.new(status: :inaccessible, text: nil, url:, reason:)
    end

    def get_following_redirects(url)
      MAX_REDIRECTS.times do
        ensure_public!(url)
        @throttle.wait(URI.parse(url).host)
        response = connection(url).get
        return response unless REDIRECT_STATUSES.include?(response.status)
        location = response.headers['location']
        # A redirect without a target is a failed response, not a redirect.
        return response if location.blank?
        url = URI.join(url, location).to_s
      end
      raise TooManyRedirectsError
    end

    def ensure_public!(url)
      uri = URI.parse(url)
      raise DisallowedUrlError unless %w[http https].include?(uri.scheme) && uri.host.present?
      addresses = Resolv.getaddresses(uri.host)
      raise DisallowedUrlError if addresses.empty? || addresses.any? { |ip| internal?(ip) }
    end

    def internal?(address)
      ip = IPAddr.new(address)
      ip.loopback? || ip.private? || ip.link_local? || ip.to_i.zero? ||
        (ip.ipv4? && IPAddr.new('100.64.0.0/10').include?(ip)) ||
        (ip.ipv6? && ip.ipv4_mapped? && internal?(ip.native.to_s))
    rescue IPAddr::InvalidAddressError
      true
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
    class DisallowedUrlError < StandardError; end
  end
end
