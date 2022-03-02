# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/importers/user_importer"

# API for communicating with the Wikimedia Event Center
class WikimediaEventCenterController < ApplicationController
  respond_to :json

  # Method for linking an Event Center event to a not-yet-in-use Dashboard Course
  # POST /wikimedia_event_center/confirm_event_sync as JSON
  # {
  #  "course_slug": string // the unique URL slug for the Course
  #  "event_id": string or integer // a unique ID for the Event Center event
  #  "organizer_username": string // the username of the Event Center event's organizer.
  #                               // Must match a user in the "facilitator" role for the Course.
  #  "secret": string // shared secret between the Event Center and the Dashboard
  # }
  # On failure, returns a JSON object with the error message and error code.
  # Possible error codes:
  #   invalid_secret - The shared secret doesn't match
  #   course_not_found - A Course with the provided slug doesn't exist
  #   not_organizer - The organizer username doesn't match a user in the "facilitator" role
  #   already_in_use - The course already has participants, so it can't be linked to the event
  #   sync_already_enabled - The course is already linked to an event
  def confirm_event_sync
    verify_secret { return }
    set_course { return }
    verify_organizer { return }
    enable_event_sync { return }
    render json: { success: true }
  end

  # Method for syncing the participant list of a Course from an Event Center event
  # POST /wikimedia_event_center/update_event_participants as JSON
  # {
  #  "course_slug": string // the unique URL slug for the Course
  #  "event_id": string or integer // a unique ID for the Event Center event
  #  "organizer_username": string // the username of the Event Center event's organizer.
  #                               // Must match a user in the "facilitator" role for the Course.
  #  "secret": string // shared secret between the Event Center and the Dashboard
  #  "participant_usernames": array of strings // usernames of event's current participants
  # }
  # Possible error codes:
  #   invalid_secret - The shared secret doesn't match
  #   course_not_found - A Course with the provided slug doesn't exist
  #   not_organizer - The organizer username doesn't match a user in the "facilitator" role
  #   sync_not_enabled - This Course isn't linked to the Event Center event (based on event_id)
  def update_event_participants
    verify_secret { return }
    set_course { return }
    verify_organizer { return }
    verify_event_sync { return }
    add_or_remove_participants
    render json: { success: true }
  end

  private

  def verify_secret
    raise InvalidSecretError if Features.wiki_ed?
    raise InvalidSecretError unless params[:secret] == ENV['WikimediaCampaignsPlatformSecret']
  rescue InvalidSecretError => e
    render json: { error: e.message, error_code: e.code }, status: :unauthorized
    yield
  end

  def set_course
    @course = Course.find_by!(slug: params[:course_slug])
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message, error_code: 'course_not_found' }, status: :not_found
    yield
  end

  def verify_organizer
    @organizer = UserImporter.new_from_username(params[:organizer_username])
    raise NotOrganizerError unless @organizer&.instructor?(@course)
  rescue NotOrganizerError => e
    render json: { error: e.message, error_code: e.code }, status: :unauthorized
    yield
  end

  def enable_event_sync
    # Only enable sync for courses that don't have participants yet.
    raise AlreadyInUseError if @course.students.any?
    # Only allow one Event to control each course
    raise SyncAlreadyEnabledError if @course.flags[:event_sync]

    @course.flags[:event_sync] = params[:event_id]
    @course.save
  rescue AlreadyInUseError, SyncAlreadyEnabledError => e
    render json: { error: e.message, error_code: e.code }, status: :conflict
    yield
  end

  def verify_event_sync
    raise SyncNotEnabledError unless @course.flags[:event_sync] == params[:event_id]
  rescue SyncNotEnabledError => e
    render json: { error: e.message, error_code: e.code }, status: :conflict
    yield
  end

  def add_or_remove_participants
    synced_participants = params[:participant_usernames].reject(&:blank?)
    current_participants = @course.students.pluck(:username)

    new_participants = synced_participants - current_participants
    add_participants(new_participants)

    removed_participants = current_participants - synced_participants
    remove_participants(removed_participants)

    # Make sure the user count is correct after adding/removing participants.
    CourseCacheManager.new(@course).update_user_count
  end

  def add_participants(new_participants)
    new_participants.each do |username|
      # A new user may or may not exist in the database yet.
      user = UserImporter.new_from_username(username)
      next unless user
      JoinCourse.new(course: @course,
                     user: user,
                     role: CoursesUsers::Roles::STUDENT_ROLE)
    end
  end

  def remove_participants(removed_participants)
    removed_participants.each do |username|
      # A user to be removed definitely exists in the database already.
      user = User.find_by!(username: username)
      CoursesUsers.find_by(course: @course,
                           user: user,
                           role: CoursesUsers::Roles::STUDENT_ROLE)&.destroy
    end
  end

  class InvalidSecretError < StandardError
    def code
      'invalid_secret'
    end

    def message
      'Invalid secret'
    end
  end

  class SyncNotEnabledError < StandardError
    def code
      'sync_not_enabled'
    end

    def message
      'Syncing with Event Center is not enabled for this course.'
    end
  end

  class AlreadyInUseError < StandardError
    def code
      'already_in_use'
    end

    def message
      'This course is already has participants.'
    end
  end

  class SyncAlreadyEnabledError < StandardError
    def code
      'sync_already_enabled'
    end

    def message
      'Sync is already enabled for this course'
    end
  end

  class NotOrganizerError < StandardError
    def code
      'not_organizer'
    end

    def message
      'This user is not an organizer for the course.'
    end
  end
end
