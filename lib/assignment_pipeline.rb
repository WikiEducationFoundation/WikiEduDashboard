# frozen_string_literal: true

# Manages the current status of an assignment.
class AssignmentPipeline
  attr_accessor :all_statuses

  module AssignmentStatuses
    NOT_YET_STARTED = 'not_yet_started'
    IN_PROGRESS = 'in_progress'
    READY_FOR_REVIEW = 'ready_for_review'
    READY_FOR_MAINSPACE = 'ready_for_mainspace'
    ASSIGNMENT_COMPLETED = 'assignment_completed'
  end

  module ReviewStatuses
    NOT_YET_STARTED = 'not_yet_started'
    PEER_REVIEW_STARTED = 'peer_review_started'
    PEER_REVIEW_COMPLETED = 'peer_review_completed'
  end

  PIPELINES = {
    assignment: [
      AssignmentStatuses::NOT_YET_STARTED,
      AssignmentStatuses::IN_PROGRESS,
      AssignmentStatuses::READY_FOR_REVIEW,
      AssignmentStatuses::READY_FOR_MAINSPACE,
      AssignmentStatuses::ASSIGNMENT_COMPLETED
    ].freeze,
    review: [
      ReviewStatuses::NOT_YET_STARTED,
      ReviewStatuses::PEER_REVIEW_STARTED,
      ReviewStatuses::PEER_REVIEW_COMPLETED
    ].freeze
  }.freeze

  def initialize(assignment:)
    @assignment = assignment
    @flags = assignment.flags
    @key = assignment.editing? ? :assignment : :review
    @all_statuses = PIPELINES[@key]
  end

  def status
    return @all_statuses.first unless @flags[@key]
    @flags[@key][:status]
  end

  def update_status(new_status)
    return unless @all_statuses.include?(new_status)
    @flags[@key] = {} unless @flags[@key]
    @flags[@key][:status] = new_status
    @flags[@key][:updated_at] = Time.zone.now
    @assignment.save
  end

  private

  def next_status
    index = @all_statuses.index(status)
    @all_statuses[index + 1] || status
  end
end
