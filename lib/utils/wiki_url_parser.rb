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
    # Match the title query parameter in URLs.
    # https://en.wikipedia.org/w/index.php?title=Greater_Cooch_Behar_People%27s_Association&oldid=1299350679
    match = @url.match(/title=(?<title>[^&]+)/)
    return match['title'] if match
    # Match the article title in articles URLs.
    # https://en.wikipedia.org/wiki/Greater_Cooch_Behar_People%27s_Association
    match = @url.match(/\/wiki\/(?<title>[^&]+)/)
    match['title'] if match
  end

  def diff
    # Match the revision id or the literal 'prev'
    match = @url.match(/diff=(?<diff>\d+|prev)/)
    match['diff'].to_i if match
  end

  def oldid
    match = @url.match(/oldid=(?<oldid>\d+)/)
    match['oldid'].to_i if match
  end
end
