# frozen_string_literal: true

class HighQualityArticleAssignmentMailer < ApplicationMailer
  def self.send_email(alert)
    return unless Features.email?
    return unless alert.article
    email(alert).deliver_now
  end

  def email(alert)
    @alert = alert
    set_course_and_recipients
    set_greeted_names
    return if @recipients.empty?
    params = { to: @recipients,
               subject: @alert.main_subject }
    params[:reply_to] = @alert.reply_to unless @alert.reply_to.nil?
    mail(params)
  end

  private

  def greeted_users
    (@course.instructors.to_a + [@alert.user]).compact
  end

  def set_greeted_names
    @greeted_names = greeted_users.map { |user| user.real_name || user.username }.to_sentence
  end

  def set_course_and_recipients
    @course = @alert.course
    @recipients = greeted_users.map(&:email) +
                  @course.nonstudents.where(greeter: true).pluck(:email)
  end
end
