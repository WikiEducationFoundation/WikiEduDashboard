# frozen_string_literal: true

class CourseAdviceMailer < ApplicationMailer
  def self.send_email(course:, stage:)
    return unless Features.email?
    return unless course.instructors.pluck(:email).any?

    staffer = SpecialUsers.classroom_program_manager
    email(course, stage, staffer).deliver_now
  end

  SUBJECT_LINES = {
    'preliminary_work' => 'SUBJECT 1',
    'drafting_and_moving' => 'SUBJECT 2',
    'peer_review' => 'SUBJECT 3',
    'assessing_contributions' => 'SUBJECT 4'
  }

  def email(course, stage, staffer)
    @course = course
    @instructors = @course.instructors
    @greeted_users = @instructors.map { |user| user.real_name || user.username }.to_sentence
    @course_link = "https://#{ENV['dashboard_url']}/courses/#{@course.slug}"

    mail(to: @instructors.pluck(:email),
         reply_to: staffer.email,
         subject: SUBJECT_LINES[stage],
         template_name: stage)
  end
end
