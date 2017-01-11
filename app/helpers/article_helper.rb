# frozen_string_literal: true

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
  }.freeze

  def article_url(article)
    return nil if article.nil?
    prefix = NS[article.namespace]
    "#{article.wiki.base_url}/wiki/#{prefix}#{article.title}"
  end

  def full_title(article)
    prefix = NS[article.namespace]
    title = article.title.tr('_', ' ')
    "#{prefix}#{title}"
  end

  def escaped_full_title(article)
    prefix = NS[article.namespace]
    "#{prefix}#{article.title}"
  end

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/CyclomaticComplexity
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
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/CyclomaticComplexity

  def rating_display(rating)
    return nil if rating.nil?
    if %w(fa ga fl).include? rating
      return rating
    else
      return rating[0]
    end
  end
end
