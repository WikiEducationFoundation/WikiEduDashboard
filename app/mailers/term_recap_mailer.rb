# frozen_string_literal: true

class TermRecapMailer < ApplicationMailer
  def self.send_recap(course, campaign)
    return unless Features.email? && Features.wiki_ed?

    email(course, campaign).deliver_now
  end

  def email(course, campaign)
    @course = course
    @instructors = course.instructors
    @campaign = campaign
    @presenter = CoursesPresenter.new(current_user: nil, campaign_param: campaign.slug)

    @greeted_users = @instructors.map { |user| user.real_name || user.username }.to_sentence

    mail(to: @instructors.map(&:email),
      subject: "Recap of #{@course.title}")
  end
end
