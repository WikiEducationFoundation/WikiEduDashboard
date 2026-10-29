# frozen_string_literal: true

require 'net/http'
require 'cgi'
require 'digest'
require 'json'
require 'fileutils'
require_dependency "#{Rails.root}/lib/claim_library/source"
require_dependency "#{Rails.root}/lib/claim_library/source_text"

module ClaimLibrary
  # Gets the text of a cited source and remembers which copy it came from.
  #
  # It tries, in order: Europe PMC's full text for anything with a PMC id, the
  # citation's own URL, the archive link the citation carries, and finally the
  # Wayback Machine snapshot nearest the revision's date. The first copy that
  # yields text wins and is cached on disk under a hash of the URL, with a
  # provenance file beside it, so a rerun reads nothing twice and anyone can
  # see which copy a judgment was made against. Failures are not cached, so
  # they are retried next time.
  class SourceFetcher
    EUROPE_PMC = 'https://www.ebi.ac.uk/europepmc/webservices/rest/%s/fullTextXML'
    WAYBACK = 'https://archive.org/wayback/available?url=%s&timestamp=%s'
    MAX_REDIRECTS = 5
    TIMEOUT = 20

    def initialize(cache_dir:, contact:)
      @cache_dir = cache_dir
      @user_agent = "WikiEduDashboard claim library (#{contact})"
      FileUtils.mkdir_p(cache_dir)
    end

    # The source behind a citation URL. `timestamp` is the revision's date,
    # used to pick the nearest archive snapshot.
    def fetch(url, archive_url: nil, timestamp: nil)
      cached(url) || remember(read(url, archive_url, timestamp))
    end

    private

    def read(url, archive_url, timestamp)
      failures = []
      candidates(url, archive_url, timestamp).each do |candidate|
        location = candidate.call
        next if location.nil?
        source = download(url, location)
        return source if source.readable?
        failures << "#{location}: #{source.error}"
      end
      Source.unreadable(url, failures.join('; ').presence || 'no copy to read')
    end

    # Each candidate is found only if the ones before it failed, so a live
    # page costs no archive lookups.
    def candidates(url, archive_url, timestamp)
      [-> { europe_pmc_url(url) }, -> { url }, -> { raw_archive(archive_url) },
       -> { wayback_url(url, timestamp) }]
    end

    def download(url, location)
      status, type, body, final_location = get(location)
      return Source.unreadable(url, "HTTP #{status}") unless status == 200
      text = SourceText.extract(body, type)
      return Source.unreadable(url, 'no readable text') if text.empty?
      Source.read(url:, read_from: final_location, text:)
    rescue StandardError => e
      Source.unreadable(url, e.message)
    end

    def europe_pmc_url(url)
      pmc_id = url.to_s[/PMC\d+/]
      pmc_id && format(EUROPE_PMC, pmc_id)
    end

    def wayback_url(url, timestamp)
      stamp = timestamp ? timestamp.strftime('%Y%m%d') : ''
      status, _type, body = get(format(WAYBACK, CGI.escape(url), stamp))
      return unless status == 200
      raw_archive(JSON.parse(body).dig('archived_snapshots', 'closest', 'url'))
    rescue JSON::ParserError, StandardError
      nil
    end

    # The archive's raw copy of a page, without the Wayback toolbar wrapped
    # around it.
    def raw_archive(archive_url)
      archive_url&.sub(%r{/web/(\d+)/}, '/web/\1id_/')
    end

    # Status, content type, body and the URL that finally answered, after
    # following redirects.
    def get(url, redirects = 0)
      uri = URI.parse(url)
      options = { use_ssl: uri.scheme == 'https', open_timeout: TIMEOUT, read_timeout: TIMEOUT }
      response = Net::HTTP.start(uri.host, uri.port, **options) do |http|
        http.request(Net::HTTP::Get.new(uri, 'User-Agent' => @user_agent))
      end
      if response.is_a?(Net::HTTPRedirection) && redirects < MAX_REDIRECTS
        return get(URI.join(url, response['location']).to_s, redirects + 1)
      end
      [response.code.to_i, response['content-type'].to_s, response.body.to_s, url]
    end

    def cached(url)
      text_path, meta_path = cache_paths(url)
      return unless File.exist?(meta_path) && File.exist?(text_path)
      Source.from_h(JSON.parse(File.read(meta_path)).merge('text' => File.read(text_path)))
    end

    def remember(source)
      return source unless source.readable?
      text_path, meta_path = cache_paths(source.url)
      File.write(text_path, source.text)
      File.write(meta_path, JSON.pretty_generate(source.provenance))
      source
    end

    def cache_paths(url)
      base = File.join(@cache_dir, Digest::SHA1.hexdigest(url.to_s))
      ["#{base}.txt", "#{base}.json"]
    end
  end
end
