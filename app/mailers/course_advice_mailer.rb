# frozen_string_literal: true

class CourseAdviceMailer < ApplicationMailer
  def self.send_email(course:, subject:)
    return unless Features.email?
    return unless course.instructors.pluck(:email).any?

    staffer = SpecialUsers.classroom_program_manager
    email(course, subject, staffer).deliver_now
  end

  SUBJECT_LINES = {
    'biographies' => '[Wiki Education] Tips for working on Wikipedia biography articles',
    'preliminary_work' => '[Wiki Education] Tips for navigating the early weeks of your Wikipedia assignment',
    'choosing_an_article' => '[Wiki Education] Student success on Wikipedia starts with article choice!',
    'bibliographies' => '[Wiki Education] Compiling a good bibliography is the key to success!',
    'drafting_and_moving' => '[Wiki Education] Tips for drafting work and moving it into the article main space',
    'peer_review' => '[Wiki Education] Tips for peer review',
    'assessing_contributions' => '[Wiki Education] How to find and assess student contributions'
  }.freeze

  def email(course, subject, staffer)
    @course = course
    @instructors = @course.instructors
    @staffer = staffer
    @group_work = @course.tag? 'working_in_groups'
    @greeted_users = @instructors.map { |user| user.real_name || user.username }.to_sentence
    @course_link = "https://#{ENV['dashboard_url']}/courses/#{@course.slug}"

    mail(to: @instructors.pluck(:email),
         reply_to: @staffer.email,
         subject: SUBJECT_LINES[subject],
         template_name: subject)
  end
end
