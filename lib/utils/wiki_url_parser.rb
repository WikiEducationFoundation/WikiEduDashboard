# frozen_string_literal: true

class WikiUrlParser
  def initialize(url)
    @url = url
  end

  def wiki
    match = @url.match(%r{https://(?<lang>[a-z]+?)\.(?<project>[a-z]+?)\.org.+})
    return unless match
    Wiki.get_or_create(language: match['lang'], project: match['project'])
  rescue Wiki::InvalidWikiError
    nil
  end

  def title
    match = @url.match(/title=(?<title>[^&]+)/)
    match['title'] if match
  end

  def diff
    match = @url.match(/diff=(?<diff>\d+)/)
    match['diff'].to_i if match
  end

  def oldid
    match = @url.match(/oldid=(?<oldid>\d+)/)
    match['oldid'].to_i if match
  end
end
