# frozen_string_literal: true

# Finds or creates a student's claim-verification assignment for a course.
# A student keeps the same assigned claim across visits (idempotent), and no
# two students in the same course are given the same claim. Claim selection
# prefers the course's subject, then claims from the course's available
# articles, then any unassigned pooled claim. Returns nil when the pool has
# no claim left to assign.
class AssignVerificationClaim
  attr_reader :assignment

  def initialize(user:, course:)
    @user = user
    @course = course
    @assignment = find_or_create
  end

  private

  def find_or_create
    existing = VerificationClaimAssignment.find_by(user: @user, course: @course)
    return existing if existing

    claim = select_claim
    return nil if claim.nil?
    VerificationClaimAssignment.create!(user: @user, course: @course,
                                        verification_claim: claim)
  end

  def select_claim
    by_subject || by_article_pool || by_general
  end

  def by_subject
    return nil if @course.subject.blank?
    available.for_subject(@course.subject).order(:id).first
  end

  def by_article_pool
    article_ids = @course.categories.flat_map(&:article_ids).uniq
    return nil if article_ids.empty?
    available.where(article_id: article_ids).order(:id).first
  end

  def by_general
    available.order(:id).first
  end

  def available
    VerificationClaim.where.not(id: assigned_claim_ids)
  end

  def assigned_claim_ids
    VerificationClaimAssignment.where(course: @course).pluck(:verification_claim_id)
  end
end
