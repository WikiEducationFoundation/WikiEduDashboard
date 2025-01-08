# frozen_string_literal: true

#= Routines for adding or removing a course to/from a campaign
class ListCourseManager
  def initialize(course, campaign)
    @course = course
    @already_approved = course.approved?
    @campaign = campaign
    @campaigns_courses_attrs = { course_id: @course.id, campaign_id: @campaign.id }
  end

  def handle_post
    return if CampaignsCourses.find_by(@campaigns_courses_attrs).present?
    CampaignsCourses.create(@campaigns_courses_attrs)

    return if @already_approved

    # Tasks for when a course is initially approved
    add_instructor_real_names if Features.wiki_ed?
    send_approval_notification_emails if Features.wiki_ed?
    add_classroom_program_manager_if_exists if Features.wiki_ed?
  end

  def handle_delete
    return unless CampaignsCourses.find_by(@campaigns_courses_attrs).present?
    CampaignsCourses.find_by(@campaigns_courses_attrs).destroy
  end

  private

  # Additional instructors may have been added before the course was approved.
  # They will not have their names associated with the CoursesUsers, so we must
  # add them now that approval has happened.
  def add_instructor_real_names
    @course.courses_users.where(role: CoursesUsers::Roles::INSTRUCTOR_ROLE).each do |cu|
      cu.update(real_name: cu.user.real_name) if cu.real_name.nil?
    end
  end

  def add_classroom_program_manager_if_exists
    cpm = SpecialUsers.classroom_program_manager
    return unless cpm && @course.type == 'ClassroomProgramCourse'
    CoursesUsers.create(user: cpm,
                        course: @course,
                        role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE,
                        real_name: cpm.real_name)
  end

  def send_approval_notification_emails
    # Send emails to each of the instructors
    @course.instructors.each do |user|
      CourseApprovalMailer.send_approval_notification(@course, user)
    end

    CourseApprovalFollowupWorker.schedule_followup_email(course: @course)

    ScheduleCourseAdviceEmails.new(@course).schedule_emails
  end
end
