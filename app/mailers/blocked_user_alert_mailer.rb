# frozen_string_literal: true

class BlockedUserAlertMailer < ApplicationMailer
  def self.send_mails_to_concerned(alert)
    return unless Features.email?
    email(alert).deliver_now
  end

  def email(alert)
    @alert = alert
    set_recipients
    return if @recipients.empty?
    params = { to: @recipients,
             subject: @alert.main_subject }
    params[:reply_to] = @alert.reply_to unless @alert.reply_to.nil?
    mail(params)
  end

  private

  def set_recipients
    @course = @alert.course
    @user = @alert.user
    @recipients = (@course.instructors.pluck(:email) +
                   @course.nonstudents.where(greeter: true).pluck(:email)) <<
                  @user.email
  end
end
