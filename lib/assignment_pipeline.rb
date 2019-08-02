# frozen_string_literal: true

# Manages the current status of an assignment.
class AssignmentPipeline
  module AssignmentStatuses
    IN_PROGRESS = 'in_progress'
    READY_FOR_REVIEW = 'ready_for_review'
    READY_FOR_MAINSPACE = 'ready_for_mainspace'
  end

  module ReviewStatuses
    PEER_REVIEWER_NEEDED = 'peer_reviewer_needed'
    PEER_REVIEW_STARTED = 'peer_review_started'
    PEER_REVIEW_COMPLETED = 'peer_review_completed'
  end

  PIPELINES = {
    assignment: [
      AssignmentStatuses::IN_PROGRESS,
      AssignmentStatuses::READY_FOR_REVIEW,
      AssignmentStatuses::READY_FOR_MAINSPACE
    ].freeze,
    review: [
      ReviewStatuses::PEER_REVIEWER_NEEDED,
      ReviewStatuses::PEER_REVIEW_STARTED,
      ReviewStatuses::PEER_REVIEW_COMPLETED
    ].freeze
  }.freeze

  def initialize(assignment:)
    @assignment = assignment
    @flags = assignment.flags
    @key = assignment.editing? ? :assignment : :review
    @pipeline = PIPELINES[@key]
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
