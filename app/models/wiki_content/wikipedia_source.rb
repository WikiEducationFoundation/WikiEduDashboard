# frozen_string_literal: true

require 'cgi'

# Represents a source referenced in a Wikipedia citation.
# Structured fields are parsed from the COinS metadata
# (<span class="Z3988">) included by all CS1 citation templates,
# with the URL falling back to the first external link in the <cite>.
class WikipediaSource
  attr_reader :title, :authors, :publisher, :date, :url, :genre, :raw_text

  def self.from_reference_li(li_node)
    li_clone = li_node.dup
    li_clone.css('.mw-cite-backlink').each(&:remove)
    raw_text = li_clone.css('.reference-text').text.strip

    coins = parse_coins(li_node)
    new(
      title:     coins['rft.btitle']&.first || coins['rft.atitle']&.first,
      authors:   extract_authors(coins),
      publisher: coins['rft.pub']&.first,
      date:      coins['rft.date']&.first,
      url:       extract_url(coins, li_node),
      genre:     coins['rft.genre']&.first,
      raw_text:
    )
  end

  def initialize(title:, authors:, publisher:, date:, url:, genre:, raw_text:)
    @title     = title
    @authors   = authors
    @publisher = publisher
    @date      = date
    @url       = url
    @genre     = genre
    @raw_text  = raw_text
  end

  private_class_method :new

  def self.pages_from_li(li_node)
    coins = parse_coins(li_node)
    (coins['rft.pages'] || coins['rft.spage'])&.first
  end

  def self.access_date_from_li(li_node)
    li_node.at_css('.reference-accessdate')
           &.text&.strip&.delete_prefix('. Retrieved ')&.strip
  end

  def self.parse_coins(li_node)
    span = li_node.at_css('span.Z3988')
    return {} unless span&.attr('title').present?

    CGI.parse(span['title'])
  end
  private_class_method :parse_coins

  def self.extract_authors(coins)
    # Named authors via aulast/aufirst, or free-form rft.au entries
    if coins['rft.aulast']&.any?
      coins['rft.aulast'].zip(coins['rft.aufirst'] || []).map do |last, first|
        [last, first].compact.join(', ')
      end
    else
      coins['rft.au'] || []
    end
  end
  private_class_method :extract_authors

  def self.extract_url(coins, li_node)
    rft_id = coins['rft_id']&.first
    return rft_id if rft_id&.start_with?('http')

    li_node.at_css('cite a[href^="http"]')&.attr('href')
  end
  private_class_method :extract_url
end
