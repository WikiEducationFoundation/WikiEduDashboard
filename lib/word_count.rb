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
  HALFAK_EN_WIKI_ESTIMATE = 5.175
  BYTES_PER_WORD = {
    'en.wikipedia.org' => HALFAK_EN_WIKI_ESTIMATE
  }.freeze

  # Byte counts from these projects are not prose, so they are excluded from the
  # character sums that back the 'Words Added' and 'Bytes Added' stats. Wikidata
  # revisions are JSON entity diffs: a single claim can add hundreds of bytes,
  # which the ratio above would report as dozens of words. Wikidata contributions
  # are reported separately, through the wikidata stats in CourseStat.
  EXCLUDED_PROJECTS = %w[wikidata].freeze

  def self.from_characters(characters)
    (characters / HALFAK_EN_WIKI_ESTIMATE).to_i
  end

  # Ids of the wikis whose character counts are excluded from course and user
  # character sums. Callers should fetch this once and reuse it, rather than
  # calling it for each record being summed.
  def self.excluded_wiki_ids
    Wiki.where(project: EXCLUDED_PROJECTS).pluck(:id)
  end
end
