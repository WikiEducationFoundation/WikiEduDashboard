# frozen_string_literal: true

require 'digest'
require_dependency "#{Rails.root}/lib/claim_library/judgment"
require_dependency "#{Rails.root}/lib/claim_library/source"

module ClaimLibrary
  # One cited sentence from one revision of an article: the claim, the
  # citation attached to it, the source as it was actually read, and the
  # judgment once a person has made one.
  #
  # The id is derived from what identifies the claim (wiki, revision, reference
  # and sentence), so extracting the same revision twice yields the same ids
  # and a library can be rebuilt without losing its judgments.
  class Record
    attr_reader :id, :wiki, :article_title, :mw_rev_id, :ref_id, :sentence, :context, :citation
    attr_accessor :source, :judgment

    def initialize(wiki:, article_title:, mw_rev_id:, ref_id:, sentence:, context:, citation:,
                   source: nil, judgment: nil)
      @wiki = wiki
      @article_title = article_title
      @mw_rev_id = mw_rev_id
      @ref_id = ref_id
      @sentence = sentence
      @context = context
      @citation = citation
      @source = source
      @judgment = judgment
      @id = Digest::SHA1.hexdigest([wiki, mw_rev_id, ref_id, sentence].join("\n"))[0, 12]
    end

    # A record for a claim and the citation it carries, as extracted from a
    # rendered revision by ClaimVerification::ClaimCitationExtractor.
    def self.from_claim(claim, citation, wiki:, article_title:, mw_rev_id:)
      new(wiki:, article_title:, mw_rev_id:, ref_id: citation.ref_id,
          sentence: claim.sentence, context: claim.context,
          citation: { 'text' => citation.cite_text, 'urls' => citation.urls,
                      'archive_urls' => citation.archive_urls,
                      'offline' => citation.offline_source? })
    end

    def self.from_h(hash)
      hash = hash.transform_keys(&:to_s)
      new(wiki: hash['wiki'], article_title: hash['article_title'],
          mw_rev_id: hash['mw_rev_id'], ref_id: hash['ref_id'],
          sentence: hash['sentence'], context: hash['context'], citation: hash['citation'],
          source: Source.from_h(hash['source']), judgment: Judgment.from_h(hash['judgment']))
    end

    def to_h
      { 'id' => id, 'wiki' => wiki, 'article_title' => article_title,
        'mw_rev_id' => mw_rev_id, 'ref_id' => ref_id, 'sentence' => sentence,
        'context' => context, 'citation' => citation,
        'source' => source&.provenance, 'judgment' => judgment&.to_h }
    end

    def judged?
      !judgment.nil?
    end

    def source_url
      citation['urls'].first
    end

    def archive_url
      citation['archive_urls'].first
    end
  end
end
