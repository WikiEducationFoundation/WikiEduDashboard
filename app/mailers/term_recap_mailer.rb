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

    @greeted_users = @instructors.map { |user| user.real_name || user.username }.to_sentence
  end
end
