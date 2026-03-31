# frozen_string_literal: true

# Represents the pairing of a WikipediaClaim with a WikipediaSource,
# along with any citation-specific details (page number, access date)
# that belong to the act of citing rather than to the source itself.
class WikipediaCitation
  attr_reader :claim, :source, :pages, :access_date

  def initialize(claim:, source:, pages: nil, access_date: nil)
    @claim       = claim
    @source      = source
    @pages       = pages
    @access_date = access_date
  end
end
