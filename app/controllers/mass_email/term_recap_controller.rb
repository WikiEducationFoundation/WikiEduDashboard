# frozen_string_literal: true

class MassEmail::TermRecapController < ApplicationController
  before_action :require_admin_permissions

  def index; end

  def send_recap_emails
    set_campaign
    eligible_courses.each do |course|
      TermRecapEmailWorker.send_email(course:, campaign: @campaign)
    end

    flash[:notice] = "Emails are going out for #{eligible_courses.count} courses."
    redirect_to '/mass_email/term_recap'
  end

  private

  def set_campaign
    @campaign = Campaign.find(params[:campaign])
  end

  def eligible_courses
    @eligible_courses ||= @campaign.courses.ended.select do |course|
      recap_not_sent?(course) && course.article_count.positive?
    end
  end

  def recap_not_sent?(course)
    course.flags[:recap_sent_at].nil?
  end
end
