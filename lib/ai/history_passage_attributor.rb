# frozen_string_literal: true

# Attributes passages of a page's plain text to the revision that added each
# one, by searching the page history for the oldest revision in an unbroken
# run of revisions containing the passage. It is the fallback for pages
# WikiWho does not cover, such as sandboxes, and works best for short
# histories: each revision it inspects costs a parse request.
#
# The search is a bisection, so it assumes a passage, once added, stayed
# until the newest revision. A passage removed and later restored is
# attributed to some revision that contained it, not necessarily the first.
class HistoryPassageAttributor
  # passages: normalized plain text paragraphs, all present in the newest revision
  # revisions: { 'revid' => ... } hashes, newest first
  # complete: whether revisions reach back to the page's first revision
  def initialize(passages:, revisions:, complete:, wiki:)
    @passages = passages
    @revisions = revisions
    @complete = complete
    @wiki = wiki
    @texts = {}
  end

  # Word counts by origin revision id, across the passages that could be traced.
  def word_counts
    @passages.each_with_object(Hash.new(0)) do |passage, counts|
      origin = origin_index(passage)
      counts[@revisions[origin]['revid']] += passage.split.size if origin
    end
  end

  private

  # The index of the oldest revision in the run that contains the passage,
  # or nil if that run continues past the oldest revision fetched.
  def origin_index(passage)
    newest = 0
    oldest = @revisions.size - 1
    return (@complete ? oldest : nil) if contains?(oldest, passage)

    # Invariant: revision `newest` contains the passage; revision `oldest` does not.
    while oldest - newest > 1
      middle = (newest + oldest) / 2
      contains?(middle, passage) ? newest = middle : oldest = middle
    end
    newest
  end

  def contains?(index, passage)
    text(@revisions[index]['revid']).include?(passage)
  end

  def text(rev_id)
    @texts[rev_id] ||= FindPreexistingFlaggedText.normalize(
      GetRevisionPlaintext.new(rev_id, @wiki, diff_mode: false).plain_text.to_s
    )
  end
end
