# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_api"

class WikiApi
  # Parses a MediaWiki diff table (action=compare output) and extracts
  # only the changed wikitext, excluding pre-existing content when new
  # text is an independent sentence addition.
  # Extracted from GetRevisionPlaintext so that other services can work
  # with the isolated wikitext of an edit.
  class DiffWikitextExtractor
    attr_reader :changed_wikitext

    def initialize(diff_table_html)
      @diff_table_html = diff_table_html
      extract_changed_wikitext
    end

    private

    # Parses the diff table HTML and extracts only the
    # changed wikitext, excluding pre-existing content
    # when new text is an independent sentence addition.
    def extract_changed_wikitext
      doc = Nokogiri::HTML(@diff_table_html)
      @changed_wikitext = extract_changed_parts(doc).reject(&:empty?).join("\n\n")
    end

    # Iterates over each <tr> in the diff table.
    # See https://en.wikipedia.org/w/index.php?title=Third_place&diff=prev&oldid=1340536495
    # The doc contains a table like:
    #
    #   <table>
    #     <tr>
    #       <td class="diff-deletedline diff-side-deleted">
    #         <div>In sociology...refers to...</div>
    #       </td>
    #       <td class="diff-addedline diff-side-added">
    #         <div>In sociology...refers to...
    #         <ins class="diffchange">Scholars have
    #         noted...</ins></div>
    #       </td>
    #     </tr>
    #     <tr>
    #       <td class="diff-empty"></td>
    #       <td class="diff-addedline diff-side-added">
    #         <div>== Criticism ==</div>
    #       </td>
    #     </tr>
    #   </table>
    #
    # Returns an array of extracted text from each <tr>.
    def extract_changed_parts(doc)
      doc.css('tr').filter_map do |row|
        extract_row_content(row)
      end
    end

    # Extracts new content from a single diff <tr>.
    # Example from Third_place diff (oldid=1340536495):
    #
    #   <td class="diff-deletedline diff-side-deleted">
    #     <div>In sociology, the '''third place''' refers
    #     to the social surroundings...</div>
    #   </td>
    #   <td class="diff-addedline diff-side-added">
    #     <div>In sociology, the '''third place''' refers
    #     to the social surroundings...
    #     <ins class="diffchange">Scholars have noted that
    #     online forums, social media platforms, and virtual
    #     communities can function as third places...</ins>
    #     </div>
    #   </td>
    #
    # The old paragraph text is unchanged. The new sentences
    # are inside <ins class="diffchange">. So this method
    # returns only the <ins> content: "Scholars have noted..."
    # For rows where text was rewritten (old != new without
    # <ins>), the full .diff-addedline text is returned.
    def extract_row_content(row)
      added = row.at_css('.diff-addedline')
      deleted = row.at_css('.diff-deletedline')
      return nil if added.nil? || added.text.strip.empty?

      ranges = independent_sentence_ranges(added, deleted)
      ranges ? ranges.map { |range| added.text[range] }.join(' ') : added.text
    end

    # When the edit only inserts whole sentences into an otherwise
    # unchanged paragraph, returns the character range in added.text
    # of each insertion; otherwise nil. From the
    # Third_place diff (oldid=1340536495):
    #
    #   <td class="diff-deletedline diff-side-deleted">
    #     <div>In sociology...refers to...</div>
    #   </td>
    #   <td class="diff-addedline diff-side-added">
    #     <div>In sociology...refers to...
    #     <ins class="diffchange">Scholars have
    #     noted...</ins></div>
    #   </td>
    #
    # Removing <ins> from added gives "In sociology...
    # refers to..." which matches deleted. Each insertion must
    # also be whole sentences where it sits, to avoid extracting
    # fragments. Insertions can come anywhere in the paragraph,
    # as in the Kingdom_of_Aksum diff (oldid=1382181955):
    #
    #   ...remain largely obscure.<ins class="diffchange">
    #   Archaeological research...settlements.<ref>...</ref></ins>
    #   Stone Age artifacts...
    def independent_sentence_ranges(added, deleted)
      return if deleted.nil? || deleted.text.strip.empty?
      return unless text_without_ins(added).strip == deleted.text.strip

      ranges = ins_ranges(added)
      return if ranges.empty?
      aligned = ranges.each_with_index.map do |range, i|
        sentence_alignment(added.text, range, *slide_bounds(ranges, i, added.text.length))
      end
      aligned.all? ? aligned : nil
    end

    # An insertion can slide over the unchanged text between the end of
    # the previous insertion and the start of the next one.
    def slide_bounds(ranges, index, text_length)
      min_begin = index.zero? ? 0 : ranges[index - 1].end
      max_end = ranges[index + 1]&.begin || text_length
      [min_begin, max_end]
    end

    # The same insertion can often be placed at more than one position.
    # MediaWiki tends to mark an inserted sentence from the end of the
    # sentence before it, leaving the new sentence's own period outside:
    #
    #   ...on the mat<ins>. The bird flew over the house</ins>. The dog...
    #
    # Sliding the range one character right gives the same text with
    # the insertion as whole sentences: " The bird flew over the house."
    # Tries each equivalent position within the unchanged text between
    # the neighbouring insertions, nearest first, and returns the first
    # that is whole sentences, or nil.
    def sentence_alignment(text, range, min_begin, max_end)
      shifts(text, range, min_begin, max_end).each do |shift|
        start = range.begin + shift
        finish = range.end + shift
        return (start...finish) if whole_sentences?(text[0...start], text[start...finish],
                                                    text[finish..])
      end
      nil
    end

    # Offsets by which the insertion can slide without changing the text:
    # right while its first character matches the one after it, left while
    # its last character matches the one before it.
    def shifts(text, range, min_begin, max_end)
      right = right_slack(text, range, max_end)
      left = left_slack(text, range, min_begin)
      [0, *(1..[right, left].max).flat_map { |n| [n, -n] }].select { |n| n.between?(-left, right) }
    end

    def right_slack(text, range, max_end)
      slack = 0
      slack += 1 while range.end + slack < max_end &&
                       text[range.begin + slack] == text[range.end + slack]
      slack
    end

    def left_slack(text, range, min_begin)
      slack = 0
      slack += 1 while range.begin - slack > min_begin &&
                       text[range.begin - slack - 1] == text[range.end - slack - 1]
      slack
    end

    # The text before an insertion ends a sentence (or is nothing),
    # the insertion starts and ends one, and the text after it
    # starts one (or is nothing).
    def whole_sentences?(before, inserted, after)
      sentence_end?(before) && sentence_start?(inserted) &&
        sentence_end?(inserted) && sentence_start?(after)
    end

    # A reference or template (like {{sfn}}). A ref's body can't
    # contain another ref tag, so a match can't run from one ref
    # across the prose to a later one.
    REF = %r{<ref[^>]*/>|<ref[^>]*>(?:(?!</?ref).)*</ref>|\{\{[^{}]*\}\}}m
    # References and templates that follow a sentence's final punctuation.
    TRAILING_REFS = /(\s*(#{REF}))+\z/
    LEADING_REFS = /\A(\s*(#{REF}))+/
    # Final punctuation, optionally inside closing quotes or parentheses.
    SENTENCE_END = /[.!?]['"”’)]*\z/
    # Link brackets, bold/italic quotes and opening quotes that
    # can come before a sentence's first letter.
    SENTENCE_PREFIX = /\A(\[\[([^\]|]*\|)?|'{2,5}|["“‘(])+/

    def sentence_end?(text)
      stripped = text.sub(TRAILING_REFS, '').rstrip
      stripped.empty? || stripped.match?(SENTENCE_END)
    end

    def sentence_start?(text)
      stripped = text.sub(LEADING_REFS, '').lstrip.sub(SENTENCE_PREFIX, '')
      stripped.empty? || stripped.match?(/\A[[:upper:][:digit:]]/)
    end

    # Character ranges in added.text of each <ins class="diffchange">,
    # with adjacent text nodes merged into one range.
    def ins_ranges(added)
      offset = 0
      added.xpath('.//text()').each_with_object([]) do |node, ranges|
        finish = offset + node.text.length
        if node.ancestors('ins.diffchange').any?
          adjacent = ranges.last&.end == offset
          adjacent ? ranges[-1] = (ranges.last.begin...finish) : ranges << (offset...finish)
        end
        offset = finish
      end
    end

    # Clones a .diff-addedline node and removes all
    # <ins class="diffchange"> elements. For example:
    #
    #   <td class="diff-addedline diff-side-added">
    #     <div>In sociology...refers to...
    #     <ins class="diffchange">Scholars have
    #     noted...</ins></div>
    #   </td>
    #
    # Returns: "In sociology...refers to..."
    def text_without_ins(added)
      clone = added.dup
      clone.css('ins.diffchange').each(&:remove)
      clone.text
    end
  end
end
