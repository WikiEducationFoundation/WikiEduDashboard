# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/claim_library/judgment"

module ClaimLibrary
  # The library as a document a person can read: a scorecard, then each judged
  # claim with its citation, the copy of the source that was read, the verdict
  # and the reason for it.
  class Report
    def initialize(library)
      @library = library
    end

    def to_markdown
      [header, scorecard, flag_table, *@library.judged.map { |record| entry(record) }].join("\n")
    end

    private

    def header
      total = @library.records.size
      judged = @library.judged.size
      "# Claim library report\n\n#{judged} of #{total} claims judged, " \
        "from #{articles.size} article#{'s' unless articles.size == 1}.\n"
    end

    def articles
      @library.records.map(&:article_title).uniq
    end

    def scorecard
      counts = @library.judged.map { |record| record.judgment.verdict }.tally
      rows = Judgment::VERDICTS.map { |verdict| "| #{verdict} | #{counts.fetch(verdict, 0)} |" }
      ["## Verdicts", '', '| Verdict | Claims |', '|---|---|', *rows, ''].join("\n")
    end

    def flag_table
      counts = @library.judged.flat_map { |record| record.judgment.flags }.tally
      return "## Flags\n\nNone recorded.\n" if counts.empty?
      rows = counts.sort_by { |_, count| -count }.map { |flag, count| "| #{flag} | #{count} |" }
      ["## Flags", '', '| Flag | Claims |', '|---|---|', *rows, ''].join("\n")
    end

    def entry(record)
      ["## #{record.article_title}: #{record.judgment.verdict}", '',
       "**Claim.** #{record.sentence}", '',
       "**Citation.** #{record.citation['text']}", '',
       "**Source.** #{source_line(record.source)}", '',
       *judgment_lines(record.judgment), ''].join("\n")
    end

    def judgment_lines(judgment)
      lines = ["**Judgment.** #{judgment.reason}"]
      lines << '' << "> #{judgment.passage}" unless judgment.passage.empty?
      lines << '' << "Flags: #{judgment.flags.join(', ')}" if judgment.flags.any?
      lines << '' << "Judged by #{judgment.annotator} on #{judgment.judged_at.to_date}."
    end

    def source_line(source)
      return 'no URL in the citation' if source.nil?
      return "#{source.kind}, could not be read (#{source.error})" unless source.readable?
      "#{source.kind}, read from #{source.read_from}"
    end
  end
end
