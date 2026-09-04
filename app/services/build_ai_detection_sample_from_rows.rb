# frozen_string_literal: true

# Builds a sample from rows of plain hashes, or from a CSV: each row names a
# unit either by a diff/revision URL or by its text, plus any of the unit
# attributes (ground_truth, provenance, notes, factors, campaign_slug,
# metadata). This is the general entry point for hand-curated sets, synthetic
# exemplars, and text collected ad hoc from any source; fetching and
# preprocessing from a particular source stays outside the Dashboard.
class BuildAiDetectionSampleFromRows < BuildAiDetectionSample
  UNIT_COLUMNS = %w[ground_truth provenance notes campaign_slug].freeze
  FACTOR_PREFIX = 'factor_'

  # CSV conventions: url_column names a diff or revision URL, text_column holds
  # the text itself (used when present). Columns named ground_truth,
  # provenance, notes and campaign_slug become unit attributes; columns
  # prefixed factor_ become factors (factor_topic → 'topic'); everything else
  # is kept as metadata. ground_truth and provenance given here apply to rows
  # that do not set their own.
  def self.from_csv(sample_name:, path:, url_column: 'url', text_column: 'text',
                    ground_truth: nil, provenance: nil, verbose: false)
    defaults = { ground_truth:, provenance: }
    rows = CSV.foreach(path, headers: true).map do |csv_row|
      csv_row_to_unit(csv_row.to_h, url_column, text_column, defaults, File.basename(path))
    end
    new(sample_name:, rows:, verbose:)
  end

  def self.csv_row_to_unit(fields, url_column, text_column, defaults, source)
    row = { url: fields.delete(url_column), text: fields.delete(text_column) }
    UNIT_COLUMNS.each { |column| row[column.to_sym] = fields.delete(column).presence }
    factors = fields.select { |key, _| key.start_with?(FACTOR_PREFIX) }
    row[:factors] = factors.transform_keys { |key| key.delete_prefix(FACTOR_PREFIX) }.compact_blank
    row[:metadata] = fields.except(*factors.keys).merge('imported_from' => source)
    defaults.merge(row.compact)
  end
  private_class_method :csv_row_to_unit

  # rows: hashes with :url and/or :text, plus optional unit attributes.
  def initialize(sample_name:, rows:, verbose: false)
    super(sample_name:, verbose:)
    rows.each do |row|
      attrs = row.to_h.symbolize_keys.compact
      text = attrs.delete(:text)
      url = attrs.delete(:url)
      text.present? ? add_text_unit(plain_text: text, url:, **attrs) : add_url_unit(url, **attrs)
    end
  end
end
