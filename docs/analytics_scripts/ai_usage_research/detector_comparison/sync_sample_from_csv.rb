# frozen_string_literal: true

# Brings a CSV-built sample in line with a regenerated CSV, for when cleaning or labels change
# after the sample was built. Run in a production Rails console:
#
#   load Rails.root.join('docs/analytics_scripts/ai_usage_research/detector_comparison',
#                        'sync_sample_from_csv.rb')
#   sync_sample_from_csv(sample_name: 'generated_stratified_2026_10',
#                        path: '/home/sage/generated_stratified_2026-10-08_v2.csv',
#                        retired_name: 'generated_stratified_2026_10_retired')
#
# Units whose text is no longer in the CSV move to retired_name rather than being deleted, so
# their scores stay attached and the old and new versions of a text can be compared. Units
# whose text is unchanged get the CSV's current notes, factors and metadata. Texts not yet in
# the sample are then added by the usual builder.

require 'csv'

def sync_sample_from_csv(sample_name:, path:, retired_name:)
  rows = CSV.read(path, headers: true).to_h do |row|
    [Digest::SHA256.hexdigest(row['text'].to_s), row]
  end
  units = AiDetectionSample.where(sample_name:)
  retired = units.where.not(text_sha256: rows.keys)
                 .update_all(sample_name: retired_name, updated_at: Time.zone.now)
  relabelled = units.where(text_sha256: rows.keys).count do |unit|
    relabel_unit(unit, rows[unit.text_sha256], File.basename(path))
  end
  summary = BuildAiDetectionSampleFromRows.from_csv(sample_name:, path:).summary
  { retired:, relabelled:, build: summary }
end

def relabel_unit(unit, row, source)
  attrs = BuildAiDetectionSampleFromRows.send(:csv_row_to_unit, row.to_h, 'url', 'text', {}, source)
  changes = { notes: attrs[:notes], factors: attrs[:factors],
              metadata: attrs[:metadata].merge('imported_from' => unit.metadata['imported_from']) }
  changes.reject! { |key, value| unit.public_send(key) == value }
  return false if changes.empty?

  unit.update!(changes)
  true
end
