# frozen_string_literal: true

#= Reads a wiki URL: the wiki it is on, the page it names and the revisions it
#= selects. Handles /wiki/ article paths (with any query or fragment),
#= /w/index.php links (edit, history, oldid, diff and curid), mobile hosts and
#= URLs without a scheme. Special:Diff, Special:MobileDiff and
#= Special:PermanentLink name no page; they are read as the diff= and oldid=
#= they stand for.
class WikiUrlParser
  # Splits a URL into host, path and query, dropping the scheme and fragment.
  URL_PARTS = %r{\A(?:(?:https?:)?//)?(?<host>[^/?#]*)(?<path>[^?#]*)(?:\?(?<query>[^#]*))?}i
  ARTICLE_PATH = %r{\A/wiki/(?<page>.+)}
  WIKI_HOST = /\A(?<lang>[a-z-]+)(?:\.m)?\.(?<project>[a-z]+)\.org\z/i
  REVISION_PAGE = %r{\ASpecial:(?<page>Diff|MobileDiff|PermanentLink|PermaLink)/(?<ids>.+)}i

  # The page title, decoded and with spaces for underscores, or nil if the URL
  # names no page.
  attr_reader :title

  # A page name given on its own rather than in a URL, such as 'Marie Curie'
  # or 'Special:Diff/123', read as it would be in a /wiki/ URL.
  def self.for_page_name(name)
    new('', page_name: name)
  end

  def initialize(url, page_name: nil)
    parts = url.to_s.match(URL_PARTS)
    @host = parts[:host]
    @params = query_params(parts[:query].to_s)
    page_name ||= parts[:path][ARTICLE_PATH, :page] || @params['title']
    read_page_name(page_name.to_s)
  end

  def wiki
    match = @host.match(WIKI_HOST)
    return unless match
    Wiki.get_or_create(language: match[:lang].downcase, project: match[:project].downcase)
  rescue Wiki::InvalidWikiError
    nil
  end

  # The revision id given as diff=, or nil if there is none or it is a keyword
  # such as 'prev'.
  def diff
    numeric_id(@params['diff'])
  end

  def oldid
    numeric_id(@params['oldid'])
  end

  # The page id given as curid=.
  def curid
    numeric_id(@params['curid'])
  end

  # diff=prev&oldid=X shows the edit that produced X, i.e. X against its parent.
  def prev_diff?
    @params['diff'] == 'prev'
  end

  # diff=next&oldid=X shows the edit after X, which needs an API lookup.
  def next_diff?
    @params['diff'] == 'next'
  end

  # True when the URL selects a revision or diff at all, as opposed to naming
  # only a page. A selector that #revision_target cannot resolve (diff=next)
  # must not be treated as a page URL.
  def revision_selector?
    !diff.nil? || !oldid.nil? || prev_diff? || next_diff?
  end

  # The revision whose text an AI detector should see, following the AI tools
  # conventions: diff=X&oldid=Y means the text added between Y and X;
  # diff=X alone or diff=prev&oldid=X means X against its parent; oldid=X
  # alone means the whole revision X. Returns nil when the URL names only a
  # page title, or a diff=next that cannot be resolved without the API.
  def revision_target
    if next_diff?
      nil
    elsif prev_diff?
      { rev_id: oldid, from_rev: nil, diff_mode: true } if oldid
    elsif diff
      revs = [oldid, diff].compact
      { rev_id: revs.max, from_rev: (revs.min if revs.count == 2), diff_mode: true }
    elsif oldid
      { rev_id: oldid, from_rev: nil, diff_mode: false }
    end
  end

  private

  def read_page_name(name)
    @title = clean_title(name)
    revision_page = @title&.match(REVISION_PAGE)
    return unless revision_page
    @title = nil
    @params.merge!(revision_page_params(revision_page))
  end

  # As MediaWiki reads them: Special:Diff/X is diff=X, Special:Diff/X/Y (or
  # Special:MobileDiff/X...Y) is oldid=X&diff=Y, and Special:PermanentLink/X is
  # oldid=X.
  def revision_page_params(revision_page)
    first, second = revision_page[:ids].split(%r{/|\.\.\.}, 2)
    return { 'oldid' => first } if revision_page[:page].match?(/\APerma/i)
    second ? { 'oldid' => first, 'diff' => second } : { 'diff' => first }
  end

  def clean_title(title)
    unescape(title).tr('_', ' ').strip.presence
  end

  # In a query string, unlike a path, '+' stands for a space.
  def query_params(query)
    query.split('&').to_h do |pair|
      key, value = pair.split('=', 2)
      [key, value.to_s.tr('+', ' ')]
    end
  end

  # Only %XX escapes are decoded, so a literal '+' is kept. MediaWiki doesn't
  # allow %XX in titles, so decoding one can't change a real title.
  def unescape(text)
    decoded = URI::DEFAULT_PARSER.unescape(text)
    decoded.valid_encoding? ? decoded : text
  end

  def numeric_id(value)
    value.to_i if value&.match?(/\A\d+\z/)
  end
end
