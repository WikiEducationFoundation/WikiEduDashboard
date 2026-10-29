# frozen_string_literal: true

# Attributes passages of an article's plain text to the revisions that added
# their words, using WikiWho's per-token authorship of the wikitext.
#
# WikiWho tokens are wikitext, so a passage does not appear in them verbatim:
# links carry their targets, and references and templates sit between the
# words. Template and reference tokens are dropped, then each passage is
# anchored where its first words appear together and its remaining words are
# matched in order, skipping any the wikitext renders differently.
class WikiWhoPassageAttributor
  WORD = /[[:word:]]+/
  ANCHOR_LENGTH = 3
  ANCHOR_ATTEMPTS = 5 # how many passage positions to try anchoring from
  LOOKAHEAD = 25 # how far ahead in the wikitext to look for each word
  MIN_MATCHED = 0.5 # share of a passage's words that must be found

  # passages: normalized plain text paragraphs
  # tokens: WikiWho rev_content tokens for the revision containing them
  def initialize(passages:, tokens:)
    @passages = passages
    @words = prose_word_tokens(tokens)
    @strings = @words.map { |token| token['str'] }
  end

  # Word counts by origin revision id, across all passages that could be found.
  def word_counts
    @passages.each_with_object(Hash.new(0)) do |passage, counts|
      passage_counts(passage)&.each { |rev_id, count| counts[rev_id] += count }
    end
  end

  private

  def passage_counts(passage)
    words = passage.downcase.scan(WORD)
    offset, position = anchor(words)
    return if position.nil?

    matched = match_in_order(words.drop(offset), position)
    return if matched.size < words.size * MIN_MATCHED

    matched.map { |index| @words[index]['o_rev_id'] }.tally
  end

  def anchor(words)
    ANCHOR_ATTEMPTS.times do |offset|
      run = words[offset, ANCHOR_LENGTH]
      break if run.nil? || run.size < ANCHOR_LENGTH

      position = (0..(@strings.size - ANCHOR_LENGTH)).find do |i|
        @strings[i, ANCHOR_LENGTH] == run
      end
      return [offset, position] if position
    end
    nil
  end

  # Indexes into @words of each passage word found, in order.
  def match_in_order(words, position)
    words.filter_map do |word|
      window_end = [position + LOOKAHEAD, @strings.size].min
      index = (position...window_end).find { |i| @strings[i] == word }
      next if index.nil?

      position = index + 1
      index
    end
  end

  # Word tokens outside templates and references.
  def prose_word_tokens(tokens)
    strings = tokens.map { |token| token['str'] }
    prose = []
    depth = 0
    index = 0
    while index < tokens.size
      string = strings[index]
      if ref_start?(strings, index)
        index = after_ref(strings, index)
        next
      end
      depth = template_depth(depth, string)
      prose << tokens[index] if depth.zero? && string.match?(/\A#{WORD}\z/)
      index += 1
    end
    prose
  end

  def template_depth(depth, string)
    return depth + 1 if string == '{{'
    return depth - 1 if string == '}}' && depth.positive?

    depth
  end

  def ref_start?(strings, index)
    strings[index] == '<' && strings[index + 1] == 'ref'
  end

  def ref_end?(strings, index)
    strings[index] == '<' && strings[index + 1] == '/' && strings[index + 2] == 'ref'
  end

  # The index after a reference: just past its opening tag if that closes
  # itself (<ref name="x" />), otherwise just past its </ref>.
  def after_ref(strings, index)
    tag_end = index_from(strings, index) { |i| strings[i] == '>' }
    return strings.size if tag_end.nil?
    return tag_end + 1 if strings[tag_end - 1] == '/'

    closing = index_from(strings, tag_end) { |i| ref_end?(strings, i) }
    return strings.size if closing.nil?

    (index_from(strings, closing) { |i| strings[i] == '>' } || strings.size - 1) + 1
  end

  def index_from(strings, start, &)
    (start...strings.size).find(&)
  end
end
