# frozen_string_literal: true

class AiEditAlertMailer < ApplicationMailer
  def self.send_emails(alert)
    return unless Features.email?

    email(alert).deliver_now
    # return unless alert.details[:prior_alert_count_for_course]&.zero?
    # instructor_advice_email(alert).deliver_now
  end

  def instructor_advice_email(alert)
    @alert = alert
    @course = @alert.course
    return unless @course
    @instructors = @alert.course.instructors
    emails = @instructors.map(&:email)
    return if emails.empty?

    @greeted_users = @instructors.map { |user| user.real_name || user.username }.to_sentence
    subject = 'Suspected AI edit — instructor next steps'
    mail(template_name: 'instructor_advice', to: emails, subject:)
  end

  def email(alert) # rubocop:disable Metrics/MethodLength
    @alert = alert
    @course = @alert.course
    return unless @course

    @intro_variant = case @alert.page_type
                     when :choose_an_article, :evaluate_an_article, :outline
                       :exercise
                     when :sandbox
                       :sandbox
                     else
                       :default
                     end

    to_email = @alert.content_experts.to_a
    to_email += [@alert.user]
    to_email += @alert.course.instructors.to_a

    emails = to_email.filter_map(&:email)
    return if emails.empty?

    subject = @alert.main_subject

    @course_link = "https://#{ENV['dashboard_url']}/courses/#{@course.slug}"

    mail(template_name: @alert.email_template_name, to: emails, subject:)
  end
end
