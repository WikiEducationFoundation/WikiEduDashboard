# frozen_string_literal: true

require 'pandoc-ruby'

# Interwiki shorthands, source: https://en.wikipedia.org/wiki/Help:Interwiki_linking#Project_titles_and_shortcuts
INTERWIKI_PREFIXES = {
  ':wikipedia' => ':w',
  ':wiktionary' => ':wikt',
  ':wikinews' => ':n',
  ':wikibooks' => ':b',
  ':wikiquote' => ':q',
  ':wikisource' => ':s',
  ':wikiversity' => ':v',
  ':wikivoyage' => ':voy'
  # ':commons' => ':c',
  # ':wikimedia' => ':wmf',
  # ':foundation' => ':wmf'
  # # Disabled due to Invalid Project:
  # ':metawikipedia' => ':m',
  # ':meta' => ':m',
  # ':wikispecies' => ':species',
  # ':mediawikiwiki' => ':mw',
  # ':phabricator' => ':phab'
}.freeze

#= Utilities to create and manipulate mediawiki wikitext
class Wikitext
  ################################
  # wikitext formatting methods #
  ################################
  def self.markdown_to_mediawiki(item)
    wikitext = PandocRuby.convert(item, from: :markdown_github, to: :mediawiki)
    wikitext = replace_code_with_nowiki(wikitext)
    wikitext = reformat_image_links(wikitext)
    wikitext = replace_at_sign_with_template(wikitext)
    reformat_links(wikitext)
  end

  def self.html_to_mediawiki(item)
    wikitext = PandocRuby.convert(item, from: :html, to: :mediawiki)
    wikitext = replace_code_with_nowiki(wikitext)
    wikitext = replace_at_sign_with_template(wikitext)
    reformat_links(wikitext)
  end

  def self.mediawiki_to_markdown(item)
    PandocRuby.convert(item, from: :mediawiki, to: :markdown_github)
  end

  # Replace instances of <code></code> with <nowiki></nowiki>
  # This lets us use backticks to format blocks of mediawiki code that we don't
  # want to be parsed in the on-wiki version of a course page.
  def self.replace_code_with_nowiki(text)
    if text.include? '<code>'
      text = text.gsub('<code>', '<nowiki>')
      text = text.gsub('</code>', '</nowiki>')
    end
    text
  end

  # Replace instances of @ with an image-based template equivalent.
  # This prevents email addresses from triggering a spam warning.
  def self.replace_at_sign_with_template(text)
    text.gsub('@', '{{@}}')
  end

  def self.assignments_to_wikilinks(assignments, home_wiki)
    return '' if assignments.blank?
    formatted_titles = assignments.map do |assignment|
      format_assignment_title(assignment, home_wiki)
    end
    '[[' + formatted_titles.join(']], [[') + ']]'
  end

  def self.format_assignment_title(assignment, home_wiki)
    # If a page is on the same wiki, no prefix is needed.
    title = format_title(assignment.article_title)
    return title if assignment.wiki_id == home_wiki.id

    project = assignment.wiki.project
    language = assignment.wiki.language

    return ":c:#{title}" if language == 'commons'

    # For other wikis a language prefix is required, except for wikidata where the language is nil
    language_prefix = language ? ":#{language}" : ''
    # If the project is different, a project prefix is also necessary.
    project_prefix = project == home_wiki.project ? '' : ":#{project}"

    (INTERWIKI_PREFIXES[project_prefix] || project_prefix) + language_prefix + ':' + title
  end

  # converts page title to a format suitable for on-wiki use
  def self.format_title(title)
    title
      .tr('_', ' ')
      .sub(/^Category:/, ':Category:') # Proper linking of categories
  end

  # Fix full urls, with or without quote marks, that have been formatted like wikilinks.
  # [["https://foo.com"|Foo]] -> [https://foo.com Foo]
  def self.reformat_links(text)
    text.gsub(/\[\["?(http.*?)"?\|(.*?)\]\]/, '[\1 \2]')
  end

  # Take file links that come out of Pandoc and attempt to create valid wiki
  # image code for them. This method assumes a recent version of Pandoc that
  # uses "File:" rather than "Image:" as the MediaWiki file prefix.
  def self.reformat_image_links(text)
    # Clean up file URLS
    # TODO: Fence this, ensure usage of wikimedia commons?

    # Get an array of [[File: ...]] and [[Image: ...]] tags from the content
    file_tags = text.scan(/\[\[[File:|Image:][^\]]*\]\]/)
    file_tags.each do |file_tag|
      # Remove the absolute portion of the file's URL
      fixed_tag = file_tag.gsub(%r{(?<=File:|Image:)[^\]]*/}, '')
      text.gsub! file_tag, fixed_tag
    end
    text
  end

  def self.substitute_bad_links(text, links)
    links.each do |link|
      safe_link = link.gsub('.', '(.)')
      text = text.gsub(link, safe_link)
    end
    text
  end
end
