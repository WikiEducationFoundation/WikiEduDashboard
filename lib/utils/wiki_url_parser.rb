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

  # The revision whose text an AI detector should see, following the AI tools
  # conventions: diff=X&oldid=Y means the text added between Y and X;
  # diff=X alone means X against its parent; oldid=X alone means the whole
  # revision X. Returns nil when the URL names only a page title.
  def revision_target
    if diff
      revs = [oldid, diff].compact
      { rev_id: revs.max, from_rev: (revs.min if revs.count == 2), diff_mode: true }
    elsif oldid
      { rev_id: oldid, from_rev: nil, diff_mode: false }
    end
  end
end
