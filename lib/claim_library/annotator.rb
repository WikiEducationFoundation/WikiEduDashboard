# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/claim_library/judgment"
require_dependency "#{Rails.root}/lib/claim_library/passage_finder"

module ClaimLibrary
  # Walks a person through the library's unjudged claims at the terminal. For
  # each one it shows the sentence in its paragraph, the citation, what kind
  # of page the source is and which copy was read, and the passages in it that
  # look relevant, then records the verdict, reason, quoted passage and flags.
  # It never suggests a verdict: the judgment is the reader's, and that is the
  # point of the library.
  class Annotator
    SKIP = 's'
    QUIT = 'q'

    def initialize(library:, fetcher:, annotator:, input: $stdin, output: $stdout)
      @library = library
      @fetcher = fetcher
      @annotator = annotator
      @input = input
      @output = output
    end

    # Returns how many judgments were recorded. The library is saved on the
    # way out as well as after each judgment, so the sources read for skipped
    # claims keep their provenance too.
    def run
      recorded = 0
      @library.unjudged.each do |record|
        outcome = annotate(record)
        break if outcome == :quit
        recorded += 1 if outcome == :recorded
      end
      @library.save
      recorded
    end

    private

    def annotate(record)
      source = fetch(record)
      show(record, source)
      loop do
        answer = ask('Verdict (number or name), s to skip, q to quit')
        return :quit if answer == QUIT
        return :skipped if answer == SKIP
        errors = record_judgment(record, verdict_from(answer), source)
        return :recorded if errors.empty?
        errors.each { |error| say("  #{error}") }
      end
    end

    def fetch(record)
      return if record.source_url.nil?
      record.source = @fetcher.fetch(record.source_url, archive_url: record.archive_url)
    end

    def show(record, source)
      say("\n#{'=' * 72}\n#{record.article_title} (revision #{record.mw_rev_id})")
      say("\nClaim:\n  #{record.sentence}")
      say("\nIn context:\n  #{record.context}")
      say("\nCitation:\n  #{record.citation['text']}")
      show_source(source, record.sentence)
      Judgment::VERDICTS.each_with_index { |verdict, i| say("  #{i + 1}. #{verdict}") }
    end

    def show_source(source, sentence)
      if source.nil?
        say("\nSource: no URL in the citation (offline source)")
      elsif source.readable?
        say("\nSource: #{source.kind}, read from #{source.read_from}")
        show_passages(source, sentence)
      else
        say("\nSource: #{source.kind}, could not be read (#{source.error})")
      end
    end

    def show_passages(source, sentence)
      passages = PassageFinder.new(source.text).passages_for(sentence)
      return say("\nNo passage in the source resembles the claim.") if passages.empty?
      say("\nLikely passages:")
      passages.each { |passage| say("  - #{passage}") }
    end

    def record_judgment(record, verdict, source)
      judgment = Judgment.new(verdict:, reason: ask('Reason (one to three sentences)'),
                              passage: ask('Passage quoted from the source (blank if none)'),
                              flags: ask("Flags, comma separated (#{Judgment::FLAGS.join(', ')})")
                                       .split(',').map(&:strip).reject(&:empty?),
                              annotator: @annotator)
      errors = judgment.errors(source_text: source&.text)
      return errors if errors.any?
      record.judgment = judgment
      @library.save
      []
    end

    def verdict_from(answer)
      index = answer.to_i
      index.positive? ? Judgment::VERDICTS[index - 1].to_s : answer
    end

    def ask(question)
      @output.print("#{question}: ")
      @output.flush
      @input.gets.to_s.strip
    end

    def say(text)
      @output.puts(text)
    end
  end
end
