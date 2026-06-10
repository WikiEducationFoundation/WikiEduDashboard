# frozen_string_literal: true

# Expedient file-backed storage for harvested source verification examples
# — (claim, cited source) pairs extracted from live Wikipedia articles by
# ExtractClaimsAndSources / FindSourceVerificationExamples. This is a
# prototyping stand-in for a real storage backend; the class-method
# interface is intended to survive a swap to one.
class SourceVerificationExampleStore
  PATH = Rails.root.join('data/source_verification_examples.json')

  # Number of hex characters of the digest used as an example's id.
  ID_LENGTH = 12

  class << self
    # Merges +examples+ (hashes as produced by the extraction services)
    # into the stored collection, assigning each a stable digest id and
    # skipping ones already present. Returns the number actually added.
    def add(examples)
      collection = all
      known_ids = collection.to_set { |example| example[:id] }
      new_examples = examples.map { |example| example.merge(id: example_id(example)) }
                             .uniq { |example| example[:id] }
                             .reject { |example| known_ids.include?(example[:id]) }
      write(collection + new_examples)
      new_examples.length
    end

    def all
      return [] unless File.exist?(PATH)
      JSON.parse(File.read(PATH)).map(&:deep_symbolize_keys)
    end

    def find(id)
      all.find { |example| example[:id] == id }
    end

    def random
      all.sample
    end

    def count
      all.length
    end

    private

    # A stable id derived from the example's content, so that re-harvesting
    # the same article doesn't create duplicates.
    def example_id(example)
      fingerprint = [example[:claim],
                     example.dig(:citations, 0, :ref_id),
                     example[:mw_rev_id]].join('|')
      Digest::SHA1.hexdigest(fingerprint)[0, ID_LENGTH]
    end

    def write(collection)
      FileUtils.mkdir_p(File.dirname(PATH))
      File.write(PATH, JSON.pretty_generate(collection))
    end
  end
end
