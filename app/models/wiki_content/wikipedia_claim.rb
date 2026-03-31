# frozen_string_literal: true

# Represents a factual claim extracted from Wikipedia prose —
# a single sentence that is followed by an inline citation.
class WikipediaClaim
  attr_reader :text

  def initialize(text)
    @text = text
  end
end
