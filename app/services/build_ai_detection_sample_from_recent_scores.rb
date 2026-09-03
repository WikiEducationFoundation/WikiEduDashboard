# frozen_string_literal: true

# Builds a sample from edits that production alerting has already scored, so a
# new detector can be compared with the production one on the same text.
# Candidates are stratified by the production max score so the sample covers
# clear negatives, the uncertain middle and clear positives rather than
# whatever the score distribution happens to be.
class BuildAiDetectionSampleFromRecentScores < BuildAiDetectionSample
  BANDS = { 'low' => 0.0...0.5, 'mid' => 0.5...0.9, 'high' => 0.9..1.0 }.freeze

  def initialize(sample_name:, per_band: 40, since: 30.days.ago,
                 check_type: RevisionAiScore::PANGRAM_V3_KEY, verbose: false)
    super(sample_name:, verbose:)
    BANDS.each do |band, range|
      candidates(range, since, check_type).limit(per_band).each { |score| add_score(score, band) }
    end
  end

  private

  def candidates(range, since, check_type)
    RevisionAiScore.where(check_origin: RevisionAiScore::COURSE_UPDATE_ORIGIN, check_type:)
                   .where(created_at: since.., max_ai_likelihood: range)
                   .includes(:wiki, :article, course: :campaigns)
                   .order(Arel.sql('RAND()'))
  end

  # Production scores the text a single edit added, i.e. the diff against its parent.
  def add_score(score, band)
    add_revision_unit(wiki: score.wiki, rev_id: score.revision_id,
                      article_id: score.article_id, course_id: score.course_id,
                      campaign_slug: score.course&.campaigns&.first&.slug,
                      namespace: score.article&.namespace,
                      metadata: { 'source_score_id' => score.id,
                                  'source_check_type' => score.check_type,
                                  'source_max_ai_likelihood' => score.max_ai_likelihood,
                                  'band' => band })
  end
end
