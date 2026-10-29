# frozen_string_literal: true

require 'json'
require 'open3'
require_dependency "#{Rails.root}/lib/claim_library/judgment"

module ClaimLibrary
  # Runs an automated verifier over the library's judged claims and compares
  # its verdicts with the people's. The verifier is any command that reads one
  # claim as JSON on standard input (the record plus the source text) and
  # writes a JSON object with a "verdict" on standard output, so a tool in any
  # language can be measured without touching this code.
  #
  # Agreement is reported overall, per human verdict and per flag, so the
  # result says not just how often a tool is right but which kinds of error
  # it catches and which it misses.
  class VerifierComparison
    Result = Data.define(:record, :human, :machine)

    attr_reader :results

    def initialize(library:, command:, fetcher:)
      @library = library
      @command = command
      @fetcher = fetcher
      @results = []
    end

    def run
      @results = @library.judged.map do |record|
        Result.new(record:, human: record.judgment.verdict, machine: verify(record))
      end
      self
    end

    def agreement(results = @results)
      return 0.0 if results.empty?
      results.count { |result| result.human == result.machine }.fdiv(results.size)
    end

    def per_verdict
      Judgment::VERDICTS.to_h { |verdict| [verdict, @results.select { |r| r.human == verdict }] }
                        .reject { |_, results| results.empty? }
                        .transform_values { |results| [agreement(results), results.size] }
    end

    def per_flag
      Judgment::FLAGS.to_h { |flag| [flag, @results.select { |r| r.record.judgment.flags.include?(flag) }] }
                     .reject { |_, results| results.empty? }
                     .transform_values { |results| [agreement(results), results.size] }
    end

    # Human verdict => machine verdict => count.
    def confusion
      @results.group_by(&:human).transform_values { |results| results.map(&:machine).tally }
    end

    def to_markdown
      ['# Verifier comparison', '', "Command: `#{@command}`", '',
       "Agreement on #{@results.size} judged claims: #{percent(agreement)}", '',
       table('By human verdict', per_verdict), table('By flag', per_flag),
       confusion_table].join("\n")
    end

    private

    def verify(record)
      source = source_for(record)
      payload = record.to_h.merge('source_text' => source&.text)
      output, status = Open3.capture2(@command, stdin_data: JSON.generate(payload))
      return 'error' unless status.success?
      JSON.parse(output).fetch('verdict', 'error').to_s
    rescue JSON::ParserError
      'error'
    end

    def source_for(record)
      return if record.source_url.nil?
      @fetcher.fetch(record.source_url, archive_url: record.archive_url)
    end

    def table(title, rows)
      lines = rows.map { |name, (rate, count)| "| #{name} | #{count} | #{percent(rate)} |" }
      ["## #{title}", '', '| | Claims | Agreement |', '|---|---|---|', *lines, ''].join("\n")
    end

    def confusion_table
      lines = confusion.flat_map do |human, machines|
        machines.map { |machine, count| "| #{human} | #{machine} | #{count} |" }
      end
      ['## Human verdict against verifier verdict', '', '| Human | Verifier | Claims |',
       '|---|---|---|', *lines, ''].join("\n")
    end

    def percent(rate)
      "#{(rate * 100).round}%"
    end
  end
end
