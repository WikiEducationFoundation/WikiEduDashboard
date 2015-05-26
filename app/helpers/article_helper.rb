#= Helpers for article views
module ArticleHelper
  NS = {
    0 => '', # Mainspace for Wikipedia articles
    1 => 'Talk:',
    2 => 'User:',
    3 => 'User_talk:',
    4 => 'Wikipedia:',
    5 => 'Wikipedia_talk:',
    10 => 'Template:',
    11 => 'Template_talk:',
    118 => 'Draft:',
    119 => 'Draft_talk:'
  }

  def article_url(article)
    language = Figaro.env.wiki_language
    prefix = NS[article.namespace]
    escaped_title = article.title.gsub(' ', '_')
    "https://#{language}.wikipedia.org/wiki/#{prefix}#{escaped_title}"
  end

  def full_title(article)
    prefix = NS[article.namespace]
    title = article.title.gsub('_', ' ')
    "#{prefix}#{title}"
  end

  def rating_priority(rating)
    case rating
    when 'fa'
      0
    when 'fl'
      1
    when 'a'
      2
    when 'ga'
      3
    when 'b'
      4
    when 'c'
      5
    when 'start'
      6
    when 'stub'
      7
    when 'list'
      8
    when nil
      9
    end
  end

  # Try to find the Wikipedia 1.0 rating of an article by parsing its talk page
  # contents.
  #
  # Adapted from https://en.wikipedia.org/wiki/User:Pyrospirit/metadata.js
  # alt https://en.wikipedia.org/wiki/MediaWiki:Gadget-metadata.js
  # We simplify this parser by folding the nonstandard ratings
  # into the corresponding standard ones. We don't want to deal with edge cases
  # like bplus and a/ga.
  def find_article_class(wikitext)
    # Handle empty talk page
    return nil if wikitext.is_a? Hash
    # rubocop:disable Metrics/LineLength
    if wikitext.match(/\|\s*(class|currentstatus)\s*=\s*fa\b/i)
      'fa'
    elsif wikitext.match(/\|\s*(class|currentstatus)\s*=\s*fl\b/i)
      'fl'
    elsif wikitext.match(/\|\s*class\s*=\s*a\b/i)
      'a' # Treat all forms of A, including A/GA, as simple A.
    elsif wikitext.match(/\|\s*class\s*=\s*ga\b|\|\s*currentstatus\s*=\s*(ffa\/)?ga\b|\{\{\s*ga\s*\|/i) && !wikitext.match(/\|\s*currentstatus\s*=\s*dga\b/i)
      'ga'
    elsif wikitext.match(/\|\s*class\s*=\s*b\b/i)
      'b'
    elsif wikitext.match(/\|\s*class\s*=\s*bplus\b/i)
      'b' # Treat B-plus as regular B.
    elsif wikitext.match(/\|\s*class\s*=\s*c\b/i)
      'c'
    elsif wikitext.match(/\|\s*class\s*=\s*start/i)
      'start'
    elsif wikitext.match(/\|\s*class\s*=\s*stub/i)
      'stub'
    elsif wikitext.match(/\|\s*class\s*=\s*list/i)
      'list'
    elsif wikitext.match(/\|\s*class\s*=\s*sl/i)
      'list' # Treat sl as regular list.
    end
    # For other niche ratings like "cur" and "future", count them as unrated.
    # rubocop:enable Metrics/LineLength
  end
end
