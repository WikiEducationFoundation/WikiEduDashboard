# frozen_string_literal: true

# Post-processes already-sanitized timeline HTML for display inside the
# Canvas iframe. Rails' sanitizer strips `target`, so links authored in the
# timeline editor navigate the iframe itself — and Dashboard-relative links
# then hit X-Frame-Options and blank the frame with no in-frame recovery.
# Every link gets target="_blank" + rel="noopener" so clicks open outside
# the iframe, and relative hrefs are absolutized against the Dashboard host
# so they resolve in the new tab. Runs strictly AFTER sanitization; it only
# adds link attributes and never loosens what the sanitizer allowed.
class RewriteLtiContentLinks
  attr_reader :html

  def initialize(sanitized_html)
    @sanitized_html = sanitized_html.to_s
    perform
  end

  private

  def perform
    fragment = Nokogiri::HTML.fragment(@sanitized_html)
    fragment.css('a[href]').each { |link| rewrite(link) }
    @html = fragment.to_html
  end

  # Fragment-only hrefs just scroll within the iframe and are left alone;
  # anything else is retargeted out of the iframe.
  def rewrite(link)
    href = link['href']
    return if href.start_with?('#')

    link['href'] = absolutize(href)
    link['target'] = '_blank'
    link['rel'] = 'noopener'
  end

  # ENV['dashboard_url'] is the bare Dashboard host — same convention as
  # WikiEdits and SyncLtiGrades, which prepend https:// to build full URLs.
  def absolutize(href)
    return href if ENV['dashboard_url'].blank?

    uri = URI.parse(href)
    return href if uri.absolute?

    URI.join("https://#{ENV['dashboard_url']}/", href).to_s
  rescue URI::InvalidURIError
    href
  end
end
