# frozen_string_literal: true

require "#{Rails.root}/lib/chat/rocket_chat"

#= Routines for adding or removing a course to/from a campaign
class ListCourseManager
  def initialize(course, campaign, request)
    @course = course
    @already_approved = course.approved?
    @campaign = campaign
    @request = request
    @campaigns_courses_attrs = { course_id: @course.id, campaign_id: @campaign.id }
  end

  def manage
    send("handle_#{@request.request_method.downcase}")
  end

  private

  def handle_post
    return if CampaignsCourses.find_by(@campaigns_courses_attrs).present?
    CampaignsCourses.create(@campaigns_courses_attrs)

    return if @already_approved

    # Tasks for when a course is initially approved
    add_instructor_real_names if Features.wiki_ed?
    send_approval_notification_emails
    RocketChat.new(course: @course).create_channel_for_course if Features.enable_chat?
  end

  # Additional instructors may have been added before the course was approved.
  # They will not have their names associated with the CoursesUsers, so we must
  # add them now that approval has happened.
  def add_instructor_real_names
    @course.courses_users.where(role: CoursesUsers::Roles::INSTRUCTOR_ROLE).each do |cu|
      cu.update(real_name: cu.user.real_name) if cu.real_name.nil?
    end
  end

  def send_approval_notification_emails
    # Send emails to each of the instructors as well as Wiki Ed staff and any
    # other non-students who are part of the course.
    @course.nonstudents.each do |user|
      CourseApprovalMailer.send_approval_notification(@course, user)
    end
  end

  def handle_delete
    return unless CampaignsCourses.find_by(@campaigns_courses_attrs).present?
    CampaignsCourses.find_by(@campaigns_courses_attrs).destroy
  end
end
