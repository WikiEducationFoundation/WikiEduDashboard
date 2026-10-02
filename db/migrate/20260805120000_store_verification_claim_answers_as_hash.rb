# frozen_string_literal: true

# Move the fact-verification exercise's answers out of the schema and into a
# serialized hash, so refining the exercise no longer means changing the
# database. The questions the exercise asks — and the answers each accepts — are
# now declared in config/claim_verification_exercise.yml; this column just holds
# whatever that names, keyed by question id.
#
# The columns dropped here were one-per-question, which coupled the shape of the
# exercise to the shape of the table: every new question needed a migration.
# Existing answers are carried across into the hash (and back out again on the
# way down), so responses submitted before this runs are preserved.
class StoreVerificationClaimAnswersAsHash < ActiveRecord::Migration[7.0]
  # Stand-in for VerificationClaimResponse, which no longer knows about the
  # per-question columns this migration has to read and write.
  class Response < ActiveRecord::Base
    self.table_name = 'verification_claim_responses'
    serialize :answers, type: Hash
  end

  # The per-question columns, in the order the exercise asked them. Each becomes
  # an `answers` key of the same name — which is why the question ids in
  # config/claim_verification_exercise.yml match these.
  ANSWER_COLUMNS = {
    source_access: :string,
    source_access_notes: :text,
    verdict: :string,
    claim_location: :text,
    verification_notes: :text,
    other_comments: :text
  }.freeze

  def up
    add_column :verification_claim_responses, :answers, :text
    Response.reset_column_information
    Response.find_each { |response| response.update!(answers: pack(response)) }
    ANSWER_COLUMNS.each_key { |column| remove_column :verification_claim_responses, column }
  end

  # Rebuilt nullable: `source_access` was NOT NULL, but a response carried down
  # may have no answer for it, and the model is what enforces that now.
  def down
    ANSWER_COLUMNS.each { |column, type| add_column :verification_claim_responses, column, type }
    Response.reset_column_information
    Response.find_each { |response| response.update!(unpack(response)) }
    remove_column :verification_claim_responses, :answers
  end

  private

  # Only the questions the student actually answered, matching how new
  # submissions are stored — blank answers aren't kept.
  def pack(response)
    ANSWER_COLUMNS.keys.index_with { |column| response[column] }.compact_blank.stringify_keys
  end

  def unpack(response)
    ANSWER_COLUMNS.keys.index_with { |column| response.answers[column.to_s] }
  end
end
