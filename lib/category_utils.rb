# frozen_string_literal: true

class CategoryUtils
  # API Documentation: https://en.wikipedia.org/w/api.php?action=query&prop=transcludedin&titles=Template:Cn
  # A page object here looks like:
  # {
  #     "pageid": 600,
  #     "ns": 0,
  #     "title": "Andorra"
  # }

  # Removing prefixes for pages outside mainspace
  # Everything till (and including) the first semicolon(:) is removed
  def self.get_titles_without_prefixes(pages)
    pages.map do |page|
      title = page['title']
      page['ns'] == Article::Namespaces::MAINSPACE ? title : title[(title.index(':') + 1)..]
    end
  end

  def self.get_titles(pages)
    pages.map { |page| page['title'] }
  end
end
