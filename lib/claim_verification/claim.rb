# frozen_string_literal: true

module ClaimVerification
  # A cited statement extracted from revision prose.
  # - sentence: the sentence the citation marker is attached to
  # - ref_ids: reference-list ids (eg 'cite_note-Smith-1') of the
  #   citations attached to the sentence
  # - context: the paragraph text up to and including the sentence,
  #   since a citation at the end of a passage may cover preceding
  #   sentences too
  Claim = Data.define(:sentence, :ref_ids, :context)
end
