# frozen_string_literal: true

# A sample is a named set of text units (the text added by a revision or diff,
# or occasionally raw text) that can be sent to several AI detectors so their
# results can be compared on identical input. The text itself is stored so
# that a detector added later scores exactly what earlier ones scored, even if
# the revision is since deleted or plaintext extraction changes. Cumulative
# course diffs regularly exceed the 64 KB of a TEXT column, hence MEDIUMTEXT.
#
# ground_truth is what we know about how the text was produced; provenance is
# how we know it; factors are named attributes (topic, author, model, prompt…)
# that link units sharing a value, so paired or grouped comparisons need no
# extra tables.
#
# Scores for a sample unit are ordinary revision_ai_scores rows with
# check_origin 'detector_comparison' and sample_id pointing here.
class CreateAiDetectionSamples < ActiveRecord::Migration[8.1]
  def change
    create_samples_table
    add_column :revision_ai_scores, :sample_id, :integer
    add_index :revision_ai_scores, :sample_id
  end

  private

  def create_samples_table # rubocop:disable Metrics/MethodLength
    create_table :ai_detection_samples do |t|
      t.string :sample_name, null: false
      t.integer :wiki_id
      t.integer :rev_id
      t.integer :from_rev_id
      t.boolean :diff_mode, default: true, null: false
      t.string :url
      t.integer :article_id
      t.integer :course_id
      t.string :campaign_slug
      t.integer :namespace
      t.string :ground_truth
      t.string :provenance
      t.text :notes
      t.text :factors
      t.text :plain_text, size: :medium
      t.string :text_sha256, limit: 64
      t.integer :word_count
      t.text :metadata
      t.timestamps
    end
    add_index :ai_detection_samples, :sample_name
    add_index :ai_detection_samples, %i[sample_name text_sha256],
              name: 'ai_detection_samples_by_text'
  end
end
