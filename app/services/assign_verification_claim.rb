# frozen_string_literal: true

# Finds or creates a student's claim-verification assignment for a course.
# A student keeps the same assigned claim across visits (idempotent), and no
# two students in the same course are given the same claim. Claim selection
# prefers the course's subject, then claims from the course's available
# articles, then any unassigned pooled claim. Returns nil when the pool has
# no claim left to assign. Pass reassign: true to switch the student to a
# different claim than the one they currently have.
class AssignVerificationClaim
  attr_reader :assignment

  def initialize(user:, course:, reassign: false)
    @user = user
    @course = course
    @reassign = reassign
    @assignment = find_or_create
  end

  private

  def find_or_create
    existing = VerificationClaimAssignment.find_by(user: @user, course: @course)
    return switch_claim(existing) if existing && @reassign
    return existing if existing

    build_assignment
  end

  # `available` excludes every claim already assigned in the course — including
  # the student's current one — so this picks a different claim, keeping the
  # current one when the pool has nothing else to offer.
  def switch_claim(existing)
    @current_claim_id = existing.verification_claim_id
    claim = select_claim
    return existing if claim.nil?
    existing.update!(verification_claim: claim)
    existing
  end

  def build_assignment
    claim = select_claim
    return if claim.nil?
    VerificationClaimAssignment.create!(user: @user, course: @course,
                                        verification_claim: claim)
  end

  def select_claim
    by_subject || by_article_pool || by_general
  end

  def by_subject
    return nil if @course.subject.blank?
    next_claim(available.for_subject(@course.subject))
  end

  def by_article_pool
    article_ids = @course.categories.flat_map(&:article_ids).uniq
    return nil if article_ids.empty?
    next_claim(available.where(article_id: article_ids))
  end

  def by_general
    next_claim(available)
  end

  # The first claim in the scope, or — when switching — the next one after the
  # student's current claim (wrapping around), so repeated switches walk through
  # the available claims instead of bouncing between the same two.
  def next_claim(scope)
    return scope.order(:id).first if @current_claim_id.nil?
    scope.where('verification_claims.id > ?', @current_claim_id).order(:id).first ||
      scope.order(:id).first
  end

  def available
    VerificationClaim.where.not(id: assigned_claim_ids)
  end

  def assigned_claim_ids
    VerificationClaimAssignment.where(course: @course).pluck(:verification_claim_id)
  end
end
