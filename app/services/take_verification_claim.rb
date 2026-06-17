# frozen_string_literal: true

# Persists the single claim a student chose to take on and records it as their
# assignment for the course. Re-harvests the article (rather than trusting
# claim text posted from the browser) and matches the chosen claim by its
# sentence and citation ref_id, so the stored claim and provenance are accurate.
# `assignment` is nil if the chosen claim can no longer be found — eg the
# article changed between viewing and taking.
class TakeVerificationClaim
  attr_reader :assignment

  def initialize(user:, course:, article:, sentence:, ref_id:)
    @user = user
    @course = course
    @article = article
    @sentence = sentence
    @ref_id = ref_id
    @assignment = perform
  end

  private

  def perform
    extraction = ExtractArticleClaims.new(@article)
    claim = extraction.claims.find { |c| c.sentence == @sentence && c.ref_ids.include?(@ref_id) }
    citation = extraction.citations.find { |cite| cite.ref_id == @ref_id }
    return if claim.nil? || citation.nil?

    assign(persist_claim(claim, citation, extraction.mw_rev_id))
  end

  def persist_claim(claim, citation, mw_rev_id)
    VerificationClaim.find_or_create_by(
      wiki: @article.wiki, mw_rev_id:, ref_id: @ref_id, sentence: claim.sentence
    ) { |record| record.assign_attributes(claim_attributes(claim, citation)) }
  end

  def claim_attributes(claim, citation)
    { context: claim.context, cite_text: citation.cite_text,
      source_url: citation.urls.first, archive_url: citation.archive_urls.first,
      offline_source: citation.offline_source?, article: @article,
      article_title: @article.title }
  end

  def assign(claim_record)
    assignment = VerificationClaimAssignment.find_or_initialize_by(user: @user, course: @course)
    assignment.update!(verification_claim: claim_record)
    assignment
  end
end
