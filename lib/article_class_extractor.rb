# frozen_string_literal: true

# Extracts the Wikipedia 1.0 class rating from the wikitext of an English Wikipedia
# article talk page.

# Adapted from https://en.wikipedia.org/wiki/User:Pyrospirit/metadata.js
# alt https://en.wikipedia.org/wiki/MediaWiki:Gadget-metadata.js
# We simplify this parser by folding the nonstandard ratings
# into the corresponding standard ones. We don't want to deal with edge cases
# like bplus and a/ga.
class ArticleClassExtractor
  def initialize(wikitext)
    @wikitext = wikitext
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def extract
    # Handle empty talk page
    return nil unless @wikitext.is_a? String

    return 'fa' if featured_article?
    return 'fl' if featured_list?
    return 'a' if a_class?
    return 'ga' if good_article?
    return 'b' if b_class?
    return 'c' if c_class?
    return 'start' if start_class?
    return 'stub' if stub_class?
    return 'list' if list_class?

    # For other niche ratings like "cur" and "future", count them as unrated.
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  private

  def featured_article?
    @wikitext =~ /\|\s*(class|currentstatus)\s*=\s*fa\b/i
  end

  def featured_list?
    @wikitext =~ /\|\s*(class|currentstatus)\s*=\s*fl\b/i
  end

  def a_class?
    # Treat all forms of A, including A/GA, as simple A.
    @wikitext =~ /\|\s*class\s*=\s*a\b/i
  end

  def good_article?
    return false if @wikitext =~ /\|\s*currentstatus\s*=\s*dga\b/i
    @wikitext.match(/\|\s*class\s*=\s*ga\b|\|\s*currentstatus\s*=\s*(ffa\/)?ga\b|\{\{\s*ga\s*\|/i)
  end

  def b_class?
    return true if @wikitext =~ /\|\s*class\s*=\s*b\b/i
    # Treat B-plus as regular B.
    @wikitext =~ /\|\s*class\s*=\s*bplus\b/i
  end

  def c_class?
    @wikitext =~ /\|\s*class\s*=\s*c\b/i
  end

  def start_class?
    @wikitext =~ /\|\s*class\s*=\s*start/i
  end

  def stub_class?
    @wikitext =~ /\|\s*class\s*=\s*stub/i
  end

  def list_class?
    return true if @wikitext =~ /\|\s*class\s*=\s*list/i
    # Treat sl as regular list.
    @wikitext =~ /\|\s*class\s*=\s*sl/i
  end
end
