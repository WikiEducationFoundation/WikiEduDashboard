# frozen_string_literal: true

# Anonymized posture: the Canvas integration no longer receives, stores, or uses
# LMS-supplied student names or emails (identity comes from the student's own
# Wikipedia OAuth). Drop the columns so the PII can't be persisted at all, and
# purge any values captured before the hardening.
class RemovePiiColumnsFromLtiContexts < ActiveRecord::Migration[8.1]
  def change
    remove_column :lti_contexts, :name, :string
    remove_column :lti_contexts, :email, :string
  end
end
