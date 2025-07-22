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

  module SandboxStatuses
    DOES_NOT_EXIST = 'does_not_exist'
    EXISTS_IN_USERSPACE = 'exists_in_userspace'
    EXISTS_IN_DRAFT_SPACE = 'exists_in_draft_space'
    EXISTS_IN_MAINSPACE = 'exists_in_mainspace'
    EXISTS_ELSEWHERE = 'exists_elsewhere'
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
    ].freeze,
    bibliography_sandbox: [
      SandboxStatuses::DOES_NOT_EXIST,
      SandboxStatuses::EXISTS_IN_USERSPACE,
      SandboxStatuses::EXISTS_IN_DRAFT_SPACE,
      SandboxStatuses::EXISTS_IN_MAINSPACE,
      SandboxStatuses::EXISTS_ELSEWHERE
    ].freeze,
    draft_sandbox: [
      SandboxStatuses::DOES_NOT_EXIST,
      SandboxStatuses::EXISTS_IN_USERSPACE,
      SandboxStatuses::EXISTS_IN_DRAFT_SPACE,
      SandboxStatuses::EXISTS_IN_MAINSPACE,
      SandboxStatuses::EXISTS_ELSEWHERE
    ].freeze,
    review_sandbox: [
      SandboxStatuses::DOES_NOT_EXIST,
      SandboxStatuses::EXISTS_IN_USERSPACE,
      SandboxStatuses::EXISTS_IN_DRAFT_SPACE,
      SandboxStatuses::EXISTS_IN_MAINSPACE,
      SandboxStatuses::EXISTS_ELSEWHERE
    ].freeze
  }.freeze

  def initialize(assignment:)
    @assignment = assignment
    @key = assignment.editing? ? :assignment : :review
    @all_statuses = PIPELINES[@key]
  end

  def status
    @assignment.flags.dig(@key, :status) || @all_statuses.first
  end

  def update_status(new_status)
    return unless @all_statuses.include?(new_status)
    @assignment.flags[@key] = {} unless @assignment.flags[@key]
    @assignment.flags[@key][:status] = new_status
    @assignment.flags[@key][:updated_at] = Time.zone.now
    @assignment.save
  end

  def draft_sandbox_status
    @assignment.flags.dig(@key, :draft) || SandboxStatuses::DOES_NOT_EXIST
  end

  def bibliography_sandbox_status
    @assignment.flags.dig(@key, :bibliography) || SandboxStatuses::DOES_NOT_EXIST
  end

  def peer_review_sandbox_status
    @assignment.flags.dig(@key, :review) || SandboxStatuses::DOES_NOT_EXIST
  end

  def update_sandbox_status(sandbox_key, new_status)
    @assignment.flags[@key] = {} unless @assignment.flags[@key]
    @assignment.flags[@key][sandbox_key] = new_status
    @assignment.save
  end
end
