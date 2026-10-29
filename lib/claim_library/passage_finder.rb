# frozen_string_literal: true

module ClaimLibrary
  # Points a reader at the places in a source most likely to bear on a claim:
  # the paragraphs that share its numbers, names, quoted phrases and longer
  # words. It is a finding aid for a person, not a judgment, and it says
  # nothing when nothing in the source resembles the claim.
  class PassageFinder
    MIN_PARAGRAPH_LENGTH = 40
    MIN_WORD_LENGTH = 5

    def initialize(source_text, limit: 3)
      @paragraphs = split(source_text)
      @limit = limit
    end

    def passages_for(sentence)
      cues = cues_in(sentence)
      return [] if cues.empty?
      @paragraphs.map { |paragraph| [score(paragraph, cues), paragraph] }
                 .select { |score, _| score.positive? }
                 .sort_by { |score, _| -score }
                 .first(@limit)
                 .map(&:last)
    end

    private

    def split(text)
      text.to_s.split(/\n+/).map(&:strip)
          .select { |paragraph| paragraph.length >= MIN_PARAGRAPH_LENGTH }
    end

    # Quoted phrases and numbers are the strongest cues, since a source either
    # has them or it doesn't; names and longer words fill in around them.
    def cues_in(sentence)
      quoted = sentence.scan(/["“]([^"”]{4,})["”]/).flatten
      numbers = sentence.scan(/\d[\d,.%]*/)
      names = sentence.scan(/\b[A-Z][a-z]{2,}\b/)
      words = sentence.scan(/\b[a-z]{#{MIN_WORD_LENGTH},}\b/)
      (quoted + numbers + names + words).map(&:downcase).uniq
    end

    def score(paragraph, cues)
      text = paragraph.downcase
      cues.count { |cue| text.include?(cue) }
    end
  end
end
