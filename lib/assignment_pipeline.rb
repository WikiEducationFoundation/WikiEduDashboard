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
    READING_ARTICLE = 'reading_the_article'
    PROVIDING_FEEDBACK = 'providing_feedback'
    POST_TO_TALK = 'post_to_talk'
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
      ReviewStatuses::READING_ARTICLE,
      ReviewStatuses::PROVIDING_FEEDBACK,
      ReviewStatuses::POST_TO_TALK,
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
end
