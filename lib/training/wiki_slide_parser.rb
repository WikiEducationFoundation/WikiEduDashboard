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
    # remove header markup for level 2 or lower
    title.gsub(/==+/, '').strip
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
    # Remove both marker and any trailing whitespace after it,
    # which may interfere with correct markdown conversion.
    @wikitext.gsub!(/<!--.+?-->\s*\n*/, '')
  end

  def remove_translate_tags
    # Remove both the tags and any excess whitespace within them,
    # which may interfere with correct markdown conversion.
    @wikitext.gsub!(/<translate>\s*/, '')
    @wikitext.gsub!(%r{\s*</translate>}, '')
  end
end
