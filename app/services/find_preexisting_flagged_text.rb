# frozen_string_literal: true

# Determines whether the text Pangram flagged in an edit was already in the
# article before that edit. The text sent for an edit can include unchanged
# context, such as the rest of a paragraph a sentence was inserted into, and
# Pangram sometimes flags only that context.
#
# Each flagged window is split into paragraphs, and a paragraph counts as
# pre-existing when it appears verbatim in the parent revision's plain text.
class FindPreexistingFlaggedText
  attr_reader :flagged_passages, :preexisting_passages

  # windows: the 'windows' of a raw Pangram response (still including 'text')
  # text: the plain text that was sent to Pangram
  def initialize(windows:, text:, parent_rev_id:, wiki:, threshold:)
    @windows = windows
    @text = text
    @parent_rev_id = parent_rev_id
    @wiki = wiki
    @threshold = threshold
    @flagged_passages = []
    @preexisting_passages = []
    find_preexisting_passages
  end

  def all_preexisting?
    @flagged_passages.any? && @flagged_passages == @preexisting_passages
  end

  private

  def find_preexisting_passages
    @flagged_passages = flagged_windows.flat_map { |window| passages(window_text(window)) }
    return if @flagged_passages.empty? || @parent_rev_id.to_i.zero?

    parent_text = parent_plain_text
    return if parent_text.nil?

    normalized_parent = normalize(parent_text)
    @preexisting_passages = @flagged_passages.select { |text| normalized_parent.include?(text) }
  end

  def flagged_windows
    @windows.select { |window| window['ai_assistance_score'] > @threshold }
  end

  # Pangram includes each window's text, but fall back to its offsets in the
  # text that was sent.
  def window_text(window)
    window['text'] || @text[window['start_index']...window['end_index']].to_s
  end

  # Paragraphs are compared separately because a window can span paragraphs
  # that were not adjacent in the article, such as two changed rows of a diff.
  def passages(text)
    text.split(/\n+/).map { |line| normalize(line) }.compact_blank
  end

  # Bracketed footnote markers like [a] or [note 1] survive plain text
  # conversion and may be numbered differently in a diff and in the full page.
  def normalize(text)
    text.gsub(/\[[^\[\]\n]{1,12}\]/, '').squish
  end

  def parent_plain_text
    GetRevisionPlaintext.new(@parent_rev_id, @wiki, diff_mode: false).plain_text
  end
end
