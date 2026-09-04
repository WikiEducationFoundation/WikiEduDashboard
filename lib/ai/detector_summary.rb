# frozen_string_literal: true

# The vendor-neutral summary of one AI detector result. Every response parser
# fills the same keys (nil where a vendor has no equivalent), so comparison
# exports and analysis never need to know which detector produced a row.
#
# Pangram scores text in windows and Originality in blocks; both appear here
# as "windows". document_score is a vendor-supplied whole-text probability
# (Originality only); max_score and mean_window_score are derived from the
# per-window scores for every vendor.
module DetectorSummary
  KEYS = %w[
    check_type vendor model_version label document_score
    max_score mean_window_score window_count windows_above_0_5 windows_above_0_9
    fraction_ai fraction_mixed fraction_human
    humanized_window_count max_humanizer_score report_url
  ].freeze

  # Parsers implement #summary_values; keys they leave out come through as nil.
  def summary
    values = summary_values
    KEYS.to_h { |key| [key, values[key]] }
  end
end
