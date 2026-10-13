# frozen_string_literal: true

#= Works out which page a student means from what they enter in an article
#= title input: a title, a [[wikilink]], or a pasted URL of the article, its
#= edit or history page, a diff or an old revision. Links that identify a
#= revision or page only by id carry no title, so those come back as ids for
#= the caller to look up on the wiki. At most one of title, revision_id and
#= page_id is set.
class ArticleTitleInputParser
  attr_reader :title, :revision_id, :page_id

  # A scheme, or a bare wiki host followed by a path.
  URL_START = %r{\A(?:(?:https?:)?//|[\w.-]+\.org/)}i
  # Drops the scheme, host and fragment, leaving the path and query.
  URL_PARTS = %r{\A(?:(?:https?:)?//)?[^/?#]*(?<path>[^?#]*)(?:\?(?<query>[^#]*))?}i
  ARTICLE_PATH = %r{\A/wiki/(?<title>.+)}
  # Every id in these is a revision of the same page, so the first one will do.
  REVISION_PAGE = %r{\ASpecial:(?:Diff|MobileDiff|PermanentLink|PermaLink)/(?<id>\d+)}i
  WIKILINK = /\A\[\[(?<target>[^|\]]*)(?:\|[^\]]*)?\]\]\z/

  def initialize(input)
    @input = input.to_s.strip
    parse
  end

  private

  def parse
    if @input.match?(URL_START)
      parse_url
    else
      @title = plain_title
    end
    revision_page = @title&.match(REVISION_PAGE)
    return unless revision_page
    @title = nil
    @revision_id = revision_page[:id].to_i
  end

  def parse_url
    url = @input.match(URL_PARTS)
    article_path = url[:path].match(ARTICLE_PATH)
    return @title = clean_title(article_path[:title]) if article_path

    params = query_params(url[:query].to_s)
    @title = clean_title(params['title'].to_s)
    @revision_id = numeric_id(params['diff']) || numeric_id(params['oldid']) unless @title
    @page_id = numeric_id(params['curid']) unless @title || @revision_id
  end

  def plain_title
    wikilink = @input.match(WIKILINK)
    clean_title(wikilink ? wikilink[:target] : @input)
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
