# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_api/article_content"

class GetRevisionPlaintext
  attr_reader :plain_text, :article_title

  def initialize(mw_rev_id, wiki, diff_mode: true, from_rev: nil)
    @wiki = wiki
    @mw_rev_id = mw_rev_id
    @diff_mode = diff_mode
    @from_rev = from_rev
    @article_content = WikiApi::ArticleContent.new(@wiki)

    generate_plaintext
  end

  private

  def generate_plaintext
    # In Diff Mode, by default we are getting the diff for a single edit,
    # so we fetch the mw_rev_id of the parent revision.
    if @diff_mode && !@from_rev
      fetch_parent_revision_id
      return if @parentid.nil?
      @from_rev = @parentid
    end

    if !@diff_mode || @from_rev.zero?
      # If there's no `from_rev`, we just
      # get the HTML for the requested revision.
      fetch_revision_html
    else
      # If it's diff mode and not the first revision, we want
      # to isolate the new content. Strategy here
      # is to get the diff table, extracted the added
      # wikitext and combine it into one string,
      # then send that through Wikipedia's parser to get HTML
      fetch_diff_table
      return if @diff_table.nil?
      generate_wikitext_from_diff_table
      fetch_parsed_changed_wikitext
    end
    generate_plaintext_from_html
  end

  def fetch_parent_revision_id
    @parentid = @article_content.parent_revision_id(@mw_rev_id)
  end

  def fetch_revision_html
    result = @article_content.revision_html(@mw_rev_id)
    @rev_html = result[:html]
    @article_title = result[:title]
    @mw_page_id = result[:page_id]
  end

  # Use action=compare to get a diff table
  # https://en.wikipedia.org/w/api.php?action=compare&torev=1315427810&fromrev=1315426424&difftype=table
  def fetch_diff_table
    result = @article_content.revision_diff(@from_rev, @mw_rev_id)
    return if result.nil?
    @article_title = result[:title]
    @mw_page_id = result[:page_id]
    @diff_table = result[:diff_html]
  end

  # Parses the diff table HTML and extracts only the
  # changed wikitext, excluding pre-existing content
  # when new text is an independent sentence addition.
  def generate_wikitext_from_diff_table
    doc = Nokogiri::HTML(@diff_table)
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

  def fetch_parsed_changed_wikitext
    @diff_html = @article_content.parse_wikitext(@changed_wikitext)
  end

  def generate_plaintext_from_html
    # First remove the <table> elements, which contain template content in exercise sandboxes
    # and are likely to contain non-prose in other cases.
    @cleaned_html = remove_non_prose_html_elements(@diff_html || @rev_html)
    # Convert the HTML to plain text
    @plain_text = ActionView::Base.full_sanitizer.sanitize(@cleaned_html)
    # Remove the edit button leftovers
    @plain_text = @plain_text.gsub('[edit]', '').strip
    # Remove inline citation leftovers
    @plain_text = @plain_text.gsub(/\[\d+\]/, '')
  end

  def remove_non_prose_html_elements(html)
    doc = Nokogiri::HTML(html)
    doc.xpath('//table').each(&:remove) # Exclude tables, like infoboxes
    doc.xpath('//cite').each(&:remove) # Exclude `cite` tags, which usually appear at the end
    doc.css('.mw-cite-backlink').each(&:remove) # Exclude backlinks that precede `cite` tags.

    doc.xpath('//figure').each(&:remove) # Exclude figure elements (images + captions)
    doc.xpath('//img').each(&:remove) # Exclude any remaining image elements

    doc.to_html
  end
end
