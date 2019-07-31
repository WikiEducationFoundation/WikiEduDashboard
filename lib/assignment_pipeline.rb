# frozen_string_literal: true

# Manages the current status of an assignment.
class AssignmentPipeline
  module AssignmentStatuses
    IN_PROGRESS = 'in_progress'
    READY_FOR_REVIEW = 'ready_for_review'
    READY_FOR_MAINSPACE = 'ready_for_mainspace'
  end

  ASSIGNMENT_STATUS_PIPELINE = [
    AssignmentStatuses::IN_PROGRESS,
    AssignmentStatuses::READY_FOR_REVIEW,
    AssignmentStatuses::READY_FOR_MAINSPACE
  ].freeze

  module ReviewStatuses
    PEER_REVIEWER_NEEDED = 'peer_reviewer_needed'
    PEER_REVIEW_STARTED = 'peer_review_started'
    PEER_REVIEW_COMPLETED = 'peer_review_completed'
  end

  REVIEW_STATUS_PIPELINE = [
    ReviewStatuses::PEER_REVIEWER_NEEDED,
    ReviewStatuses::PEER_REVIEW_STARTED,
    ReviewStatuses::PEER_REVIEW_COMPLETED
  ].freeze

  def initialize(assignment:)
    @assignment = assignment
    @flags = assignment.flags

    role = Assignment::ROLE_NAMES[assignment.role]
    editing = role == 'Editing'
    @key = editing ? :assignment : :review
    @pipeline = editing ? ASSIGNMENT_STATUS_PIPELINE : REVIEW_STATUS_PIPELINE
  end

  def status
    return @pipeline.first unless @flags[@key]
    @flags[@key][:status]
  end

  def update_status(new_status)
    return unless @pipeline.include?(new_status)
    @flags[@key] = {} unless @flags[@key]
    @flags[@key][:status] = new_status
    @flags[@key][:updated_at] = Time.zone.now
    @assignment.save
  end

  def next_status
    index = @pipeline.index(status)
    @pipeline[index + 1] || status
  end
end
