# frozen_string_literal: true

# Every detector's stored results for a set of detector comparison units,
# counting results stored on identical copies of a text in other current
# samples: the September Originality test scored copies of 30 baseline texts,
# and the same text gives the same result whichever unit holds it. Per detector,
# a successful result beats a failed call, and a unit's own result beats a copy's.
class CollectDetectorComparisonScores
  attr_reader :result # unit id => the RevisionAiScores that stand for it

  def initialize(units)
    @units = units
    @copies = copies_by_text
    @result = @units.to_h { |unit| [unit.id, merged(unit)] }
  end

  private

  def merged(unit)
    copied = Array(@copies[unit.text_sha256]).reject { |score| score.sample_id == unit.id }
    (unit.revision_ai_scores.to_a + copied).group_by(&:check_type).values.map do |scores|
      scores.find(&:avg_ai_likelihood) || scores.first
    end
  end

  def copies_by_text
    AiDetectionSample.select(:id, :text_sha256)
                     .where(text_sha256: @units.map(&:text_sha256).compact.uniq)
                     .where.not(id: @units.map(&:id))
                     .where.not('sample_name LIKE ?', SummarizeDetectorComparison::RETIRED_SAMPLES)
                     .includes(:revision_ai_scores)
                     .group_by(&:text_sha256)
                     .transform_values { |copies| copies.flat_map(&:revision_ai_scores) }
  end
end
