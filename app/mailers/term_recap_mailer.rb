# frozen_string_literal: true

class TermRecapMailer < ApplicationMailer
  WORDS_PER_STUDENT_CUTOFF = 200

  def self.send_recap(course, campaign)
    return unless Features.email? && Features.wiki_ed?

    if course.average_word_count > WORDS_PER_STUDENT_CUTOFF
      email(course, campaign).deliver_now
    else
      basic_email(course, campaign).deliver_now
    end
  end

  def email(course, campaign)
    prepare_email(course, campaign)
    mail(to: @instructors.map(&:email), subject: "Recap of #{@course.title}")
  end

  def basic_email(course, campaign)
    prepare_email(course, campaign)
    mail(to: @instructors.map(&:email), subject: "Recap of #{@course.title}")
  end

  private

  def prepare_email(course, campaign)
    @course = course
    @instructors = course.instructors
    @campaign = campaign
    @presenter = CoursesPresenter.new(current_user: nil, campaign_param: campaign.slug)
    set_cohort_counts(campaign)

    @greeted_users = @instructors.map { |user| user.real_name || user.username }.to_sentence
  end

  # The cohort sentence pairs these with the presenter's word count, which
  # leaves out private courses, so these leave them out too.
  def set_cohort_counts(campaign)
    courses = campaign.nonprivate_courses
    @cohort_course_count = courses.count
    @cohort_student_count = CoursesUsers.where(course: courses,
                                               role: CoursesUsers::Roles::STUDENT_ROLE)
                                        .distinct.count(:user_id)
  end
end
