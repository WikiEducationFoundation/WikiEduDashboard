# frozen_string_literal: true

class ArticleUtils
  # This method takes user input and tries to convert it into a valid article title
  def self.format_article_title(article_title, wiki = nil)
    formatted_title = String.new(article_title)
    # title case is not used for Wiktionary pages
    unless wiki&.project == 'wiktionary'
      first_letter = formatted_title[0]
      # Use mb_chars so that we can capitalize unicode letters too.
      formatted_title[0] = first_letter.mb_chars.capitalize.to_s
    end
    formatted_title = formatted_title.tr(' ', '_')
    formatted_title
  end
end
