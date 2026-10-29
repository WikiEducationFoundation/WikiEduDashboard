# frozen_string_literal: true

require 'open3'
require 'tempfile'

module ClaimLibrary
  # Turns a fetched document into plain text with its paragraphs intact, so a
  # reader can find a passage and quote it. Nothing is summarised or reworded.
  module SourceText
    module_function

    def extract(body, content_type)
      case content_type.to_s
      when /pdf/ then from_pdf(body)
      when /xml/ then from_xml(body)
      else from_html(body)
      end
    end

    def from_html(body)
      doc = Nokogiri::HTML(body)
      doc.css('script, style, nav, header, footer, noscript, aside').each(&:remove)
      blocks = doc.css('p, h1, h2, h3, h4, li, td, blockquote, dd').map(&:text)
      text = paragraphs(blocks)
      text.empty? ? paragraphs(doc.text.split("\n")) : text
    end

    # JATS XML, as Europe PMC serves it for open-access articles. Citation
    # markers are dropped so sentences read as the author wrote them.
    def from_xml(body)
      doc = Nokogiri::XML(body)
      doc.css('xref, ref-list, table-wrap, fig').each(&:remove)
      paragraphs(doc.css('article-title, title, p').map(&:text))
    end

    # Needs pdftotext (poppler) on the machine; without it a PDF counts as
    # unreadable rather than silently yielding nothing useful.
    def from_pdf(body)
      return '' unless pdftotext_available?
      Tempfile.create(['source', '.pdf']) do |file|
        file.binmode
        file.write(body)
        file.flush
        output, status = Open3.capture2('pdftotext', '-layout', file.path, '-')
        status.success? ? paragraphs(output.split(/\n\s*\n/)) : ''
      end
    end

    def pdftotext_available?
      _out, status = Open3.capture2e('which', 'pdftotext')
      status.success?
    end

    def paragraphs(blocks)
      blocks.map { |block| block.to_s.gsub(/\s+/, ' ').strip }
            .reject(&:empty?)
            .join("\n\n")
    end
  end
end
