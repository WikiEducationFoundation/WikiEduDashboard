# frozen_string_literal: true

#= Takes wikitext for an on-wiki slide and extracts title and content
class WikiSlideParser
  def initialize(wikitext)
    @wikitext = wikitext
    set_utf8_encoding
    remove_noinclude
    remove_translation_markers
    remove_translate_tags
  end

  # The first translated line is the slide title
  def title
    title = @wikitext.lines.first.chomp
    title.gsub(/==+/, '') # remove header markup for level 2 or lower
  end

  # Everything after the first translated line is the slide content
  def content
    wikitext = @wikitext.lines[1..-1].join
    wikitext.gsub!(/^\n*/) # Remove leading newlines
    Wikitext.mediawiki_to_markdown(wikitext)
  end

  private

  def set_utf8_encoding
    @wikitext = @wikitext.force_encoding('UTF-8')
  end

  def remove_noinclude
    @wikitext.gsub!(%r{<noinclude>.*?</noinclude>\n*}m, '')
  end

  def remove_translation_markers
    @wikitext.gsub!(/<!--.+?-->\n*/, '')
  end

  def remove_translate_tags
    @wikitext.gsub!(/<translate>/, '')
    @wikitext.gsub!(%r{</translate>}, '')
  end
end
