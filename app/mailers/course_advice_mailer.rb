# frozen_string_literal: true

class CourseAdviceMailer < ApplicationMailer
  def self.send_email(course:, stage:)
    return unless Features.email?
    return unless course.instructors.pluck(:email).any?

    staffer = SpecialUsers.classroom_program_manager
    email(course, stage, staffer).deliver_now
  end

  SUBJECT_LINES = {
    'preliminary_work' => 'Tips for navigating the early weeks of your Wikipedia assignment',
    'drafting_and_moving' => 'Tips for drafting work and moving it into the article main space',
    'peer_review' => 'Tips for peer review',
    'assessing_contributions' => 'How to find and assess student contributions'
  }.freeze

  def email(course, stage, staffer)
    @course = course
    @instructors = @course.instructors
    @staffer = staffer
    @group_work = @course.tag? 'working_in_groups'
    @greeted_users = @instructors.map { |user| user.real_name || user.username }.to_sentence
    @course_link = "https://#{ENV['dashboard_url']}/courses/#{@course.slug}"

    mail(to: @instructors.pluck(:email),
         reply_to: @staffer.email,
         subject: SUBJECT_LINES[stage],
         template_name: stage)
  end
end
