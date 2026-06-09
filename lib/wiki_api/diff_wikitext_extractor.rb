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

      ins_elements = added.css('ins.diffchange')

      if independent_addition?(added, deleted, ins_elements)
        ins_elements.map(&:text).join(' ')
      else
        added.text
      end
    end

    # Returns true when the edit is a pure sentence-level
    # addition. From the Third_place diff (oldid=1340536495):
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
    # refers to..." which matches deleted. Also checks
    # that <ins> content starts a new sentence, to avoid
    # extracting mid-sentence fragments.
    def independent_addition?(added, deleted, ins_elements)
      return false unless ins_elements.any?
      return false if deleted.nil? || deleted.text.strip.empty?
      return false unless text_without_ins(added).strip == deleted.text.strip

      # Only treat as independent if the new content begins
      # a new sentence: the preceding text ends with sentence
      # punctuation and the new content starts with a capital.
      preceding = text_without_ins(added).strip
      first_ins_text = ins_elements.first.text.strip
      preceding.match?(/[.!?]['"]?\z/) && first_ins_text.match?(/\A[A-Z]/)
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
