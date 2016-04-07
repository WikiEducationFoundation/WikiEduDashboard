require 'pandoc-ruby'

#= Utilities to create and manipulate mediawiki wikitext
class Wikitext
  ################################
  # wikitext formatting methods #
  ################################
  def self.markdown_to_mediawiki(item)
    wikitext = PandocRuby.convert(item, from: :markdown, to: :mediawiki)
    wikitext = replace_code_with_nowiki(wikitext)
    wikitext = reformat_image_links(wikitext)
    wikitext = replace_at_sign_with_template(wikitext)
    wikitext
  end

  def self.html_to_mediawiki(item)
    wikitext = PandocRuby.convert(item, from: :html, to: :mediawiki)
    wikitext = replace_code_with_nowiki(wikitext)
    wikitext = replace_at_sign_with_template(wikitext)
    wikitext = reformat_links(wikitext)
    wikitext
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
    text = text.gsub('@', '{{@}}')
    text
  end

  def self.titles_to_wikilinks(titles)
    return '' if titles.blank?
    titles_with_spaces = titles.map { |t| t.tr('_', ' ') }
    wikitext = '[[' + titles_with_spaces.join(']], [[') + ']]'
    wikitext
  end

  # Fix full urls that have been formatted like wikilinks.
  # [["https://foo.com"|Foo]] -> [https://foo.com Foo]
  def self.reformat_links(text)
    text = text.gsub(/\[\["(http.*?)"\|(.*?)\]\]/, '[\1 \2]')
    text
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
