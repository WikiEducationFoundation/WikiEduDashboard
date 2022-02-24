# frozen_string_literal: true

# API for communicating with the Wikimedia Campaigns Platform
class WikimediaCampaignsPlatformController < ApplicationController
  before_action :verify_secret

  # TODO
  # Remove wiki, assume meta
  # Add endpoint for confirming connection between new event and dashboard course
  # write up list of failure states, English messages, and send them to Campaigns Platform team

  def confirm_event_sync
    set_course
    verify_organizer
    verify_or_update_course_settings
  end

  def update_event_participants
    set_course
    set_wiki
    verify_organizer
    add_or_remove_participants
  end

  private

  def set_course
    @course = Course.find_by!(slug: params[:course_slug])
  end

  # remove, assume meta
  def set_wiki
    @wiki = Wiki.get_or_create(language: params[:language], project: params[:project])
  end

  def verify_organizer
    @organizer = new_from_username(username: params[:organizer_username])
    raise NotPermittedError unless @organizer.instructor?(@course)
  end

  def add_or_remove_participants
    current_participants = @course.students.pluck(:username)

    new_participants = params[:participant_usernames] - current_participants
    new_participants.each do |username|
      # A new user may or may not exist in the database yet.
      user = UserImporter.new_from_username(username, @wiki)
      JoinCourse.new(course: @course,
                     user: user,
                     role: CoursesUsers::Roles::STUDENT_ROLE)
    end

    removed_participants = current_participants - params[:participant_usernames]
    removed_participants.each do |username|
      # A user to be removed definitely exists in the database already.
      user = User.find_by!(username: username)
      CoursesUsers.find_by(course: @course,
                           user: user,
                           role: CoursesUsers::Roles::STUDENT_ROLE)&.destroy
    end

    # Make sure the user count is correct after adding/removing participants.
    CourseCacheManager.new(@course).update_user_count
  end

  def verify_secret
    raise NotPermittedError unless params[:secret] == ENV['WikimediaCampaignsPlatformSecret']
  end
end
