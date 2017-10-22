# frozen_string_literal: true

#= Converts character counts to word counts
class WordCount
  # Aaron Halfaker has done some analysis on the relationship between
  # byte length and visible characters in English Wikipedi articles.
  # According to his regression, the ratio is 1.15 bytes per visible character.
  # Combining that with standard English ratio of 4.5 letters per word, and
  # we get 5.175 characters / word.
  # See discussion here: https://lists.wikimedia.org/pipermail/wiki-research-l/2013-August/002999.html
  # See graph with regression line here: https://commons.wikimedia.org/wiki/File:Bytes.content_length.scatter.correlation.enwiki.png
  # This is just a rough estimate, pending research on how bytes *added*
  # relates to changes in readable word count for work by student editors.
  CHARACTERS_PER_WORD = 5.175

  def self.from_characters(characters)
    (characters / CHARACTERS_PER_WORD).to_i
  end
end
