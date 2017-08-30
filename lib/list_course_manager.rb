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
    # Task for when a course is initially approved
    send_approval_notification_emails
    RocketChat.new(course: @course).create_channel_for_course if Features.enable_chat?
  end

  def handle_delete
    return unless CampaignsCourses.find_by(@campaigns_courses_attrs).present?
    CampaignsCourses.find_by(@campaigns_courses_attrs).destroy
  end

  def send_approval_notification_emails
    # Send emails to each of the instructors as well as Wiki Ed staff and any
    # other non-students who are part of the course.
    @course.nonstudents.each do |user|
      CourseApprovalMailer.send_approval_notification(@course, user)
    end
  end
end
