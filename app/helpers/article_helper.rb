#= Helpers for article views
module ArticleHelper
  NS = {
    Article::Namespaces::MAINSPACE => '',
    Article::Namespaces::TALK => 'Talk:',
    Article::Namespaces::USER => 'User:',
    Article::Namespaces::USER_TALK => 'User_talk:',
    Article::Namespaces::WIKIPEDIA => 'Wikipedia:',
    Article::Namespaces::WIKIPEDIA_TALK => 'Wikipedia_talk:',
    Article::Namespaces::TEMPLATE => 'Template:',
    Article::Namespaces::TEMPLATE_TALK => 'Template_talk:',
    Article::Namespaces::DRAFT => 'Draft:',
    Article::Namespaces::DRAFT_TALK => 'Draft_talk:'
  }

  # TODO: Move to Article#url ?
  def article_url(article)
    return nil if article.nil?
    # TODO: i18n namespace lookup
    prefix = NS[article.namespace]
    "#{article.wiki.base_url}wiki/#{prefix}#{article.title}"
  end

  def full_title(article)
    prefix = NS[article.namespace]
    title = article.title.tr('_', ' ')
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
    # rubocop:disable Style/RegexpLiteral
    elsif wikitext.match(/\|\s*class\s*=\s*ga\b|\|\s*currentstatus\s*=\s*(ffa\/)?ga\b|\{\{\s*ga\s*\|/i) && !wikitext.match(/\|\s*currentstatus\s*=\s*dga\b/i)
      'ga'
    # rubocop:enable Style/RegexpLiteral
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

  def rating_display(rating)
    return nil if rating.nil?
    if %w(fa ga fl).include? rating
      return rating
    else
      return rating[0]
    end
  end
end
