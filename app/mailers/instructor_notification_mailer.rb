class InstructorNotificationMailer < ApplicationMailer
  def self.send_email(alert)
    return unless Features.email?
    email(alert).deliver_now
  end

  def email(alert)
    @alert = alert
    set_email_parameters
    params = { to: @instructors.pluck(:email),
               bcc: @alert.bcc_to_salesforce_email, # Todo:Pv
               subject: @alert.main_subject }
    params[:reply_to] = @alert.reply_to unless @alert.reply_to.nil?
    mail(params)
  end

  private

  def set_email_parameters
    @course = @alert.course
    @instructors = @course.instructors
    @greeted_users = @instructors.map { |user| user.real_name || user.username }.to_sentence
    @course_link = "https://#{ENV['dashboard_url']}/courses/#{@course.slug}"
    @students_link = "#{@course_link}/students"
    @timeline_link = "#{@course_link}/timeline"
    @message = @alert.message
  end
end
