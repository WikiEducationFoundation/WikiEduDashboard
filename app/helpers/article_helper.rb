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

  def url(title, namespace, language)
     escaped_title = title.gsub(' ', '_')
     prefix = NS[namespace]
    "https://#{language}.wikipedia.org/wiki/#{prefix}#{escaped_title}"
  end

  def title_with_namespace(title, namespace)
    prefix = NS[namespace]
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
end
