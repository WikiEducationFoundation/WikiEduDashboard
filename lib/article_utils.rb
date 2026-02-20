# frozen_string_literal: true

class ArticleUtils
  # Interwiki prefixes that can appear in article titles
  INTERWIKI_PREFIXES = {
    'w' => 'wikipedia',
    'wikt' => 'wiktionary',
    'n' => 'wikinews',
    'b' => 'wikibooks',
    'q' => 'wikiquote',
    's' => 'wikisource',
    'v' => 'wikiversity',
    'voy' => 'wikivoyage',
    'c' => 'commons',
    'wmf' => 'wikimedia',
    'm' => 'metawikipedia',
    'species' => 'wikispecies',
    'mw' => 'mediawiki'
  }.freeze

  # Valid project names
  VALID_PROJECTS = ['wikipedia', 'wiktionary', 'wikinews', 'wikibooks', 'wikiquote',
                    'wikisource', 'wikiversity', 'wikivoyage', 'commons', 'wikimedia',
                    'wikidata', 'metawikipedia', 'wikispecies', 'mediawiki'].freeze

  # Parse interwiki format from article title like "en:Article" or "en:wiktionary:Article"
  # Returns a hash with :title, :project, :language, or nil if not interwiki format
  def self.parse_interwiki_format(article_title)
    # Pattern: (optional leading colon)(2-3 char language code)(optional :project):title
    match = article_title.match(/^(:)?([a-z]{2,3}(?:-[a-z]+)?)(?::([a-z]+))?:(.+)$/i)
    return nil unless match

    _leading_colon, language, project_code, title = match.captures

    # If project is specified, resolve the code or name
    if project_code
      project = INTERWIKI_PREFIXES[project_code] || 
                (VALID_PROJECTS.include?(project_code) ? project_code : nil)
      # If we can't resolve the project code, it might not be a project code at all,
      # but part of the title (e.g., "en:User:Example"). Treat it as wikipedia.
      if project.nil?
        title = "#{project_code}:#{title}"
        project = 'wikipedia'
      end
    else
      project = 'wikipedia'
    end

    {
      title: title,
      project: project,
      language: language
    }
  end

  # This method takes user input and tries to convert it into a valid article title
  def self.format_article_title(article_title, wiki = nil)
    formatted_title = String.new(article_title)
    # title case is not used for Wiktionary pages
    unless wiki&.project == 'wiktionary'
      first_letter = formatted_title[0]
      # Use mb_chars so that we can capitalize unicode letters too.
      formatted_title[0] = first_letter.mb_chars.capitalize.to_s if first_letter
    end
    formatted_title = formatted_title.tr(' ', '_')
    formatted_title
  end
end
