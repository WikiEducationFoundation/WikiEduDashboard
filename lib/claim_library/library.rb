# frozen_string_literal: true

require 'json'
require 'fileutils'
require_dependency "#{Rails.root}/lib/claim_library/record"

module ClaimLibrary
  # The library on disk: one JSON record per line. Line-per-record keeps the
  # file readable in a diff and lets it be shared and used without the
  # Dashboard. Records are keyed by id, so extracting a revision again adds
  # only what is new and never touches an existing judgment.
  class Library
    attr_reader :path, :records

    def initialize(path)
      @path = path
      @records = load
    end

    # Adds the records not already in the library; returns how many were new.
    def add(new_records)
      known = records.to_set(&:id)
      added = new_records.reject { |record| known.include?(record.id) }
      records.concat(added)
      added.size
    end

    def find(id)
      records.find { |record| record.id == id }
    end

    def judged
      records.select(&:judged?)
    end

    def unjudged
      records.reject(&:judged?)
    end

    def save
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, records.map { |record| JSON.generate(record.to_h) }.join("\n") << "\n")
    end

    private

    def load
      return [] unless File.exist?(path)
      File.readlines(path, chomp: true).reject(&:empty?)
          .map { |line| Record.from_h(JSON.parse(line)) }
    end
  end
end
