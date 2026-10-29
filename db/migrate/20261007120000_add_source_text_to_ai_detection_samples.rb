# frozen_string_literal: true

# The unit's text as written, before it was cleaned into plain_text for the
# detectors: wikitext with its references, a model's reply, Agpedia markdown.
# Kept for later analysis of the citations (claim verification).
class AddSourceTextToAiDetectionSamples < ActiveRecord::Migration[8.1]
  def change
    add_column :ai_detection_samples, :source_text, :text, size: :medium
    add_column :ai_detection_samples, :source_format, :string
  end
end
