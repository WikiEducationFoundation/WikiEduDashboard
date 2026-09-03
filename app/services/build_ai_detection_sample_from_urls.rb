# frozen_string_literal: true

# Builds a sample from a list of diff or revision URLs, each optionally carrying
# a ground truth, a campaign slug and free-form metadata. This is the general
# entry point for hand-curated sets and for CSVs such as the March 2026
# comparison or the WVS Northeastern experiment dataset.
class BuildAiDetectionSampleFromUrls < BuildAiDetectionSample
  UNIT_ATTRIBUTES = %w[ground_truth campaign_slug].freeze

  # Reads a CSV whose url_column holds the URLs. ground_truth and campaign_slug
  # columns, if present, become unit attributes; every other column is kept in
  # the unit's metadata. A default ground_truth applies to rows without one.
  def self.from_csv(sample_name:, path:, url_column: 'url', ground_truth: nil, verbose: false)
    rows = CSV.foreach(path, headers: true).map do |csv_row|
      fields = csv_row.to_h
      { url: fields.delete(url_column),
        ground_truth: fields.delete('ground_truth').presence || ground_truth,
        campaign_slug: fields.delete('campaign_slug'),
        metadata: fields.merge('imported_from' => File.basename(path)) }
    end
    new(sample_name:, rows:, verbose:)
  end

  # rows: hashes with :url and optionally :ground_truth, :campaign_slug, :metadata
  def initialize(sample_name:, rows:, verbose: false)
    super(sample_name:, verbose:)
    rows.each do |row|
      attrs = row.to_h.symbolize_keys
      add_url_unit(attrs.delete(:url), **attrs.compact)
    end
  end
end
