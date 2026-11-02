# frozen_string_literal: true

# Decision emails for applications to a Scholars & Scientists course (Wiki
# Education Dashboard only). They come from the scholars_and_scientists_manager
# special user, or from the Dashboard's own address while that position is
# empty. The acceptance email's body is the course's staff-written message,
# from its application form settings.
class CourseApplicationMailer < ApplicationMailer
  def self.send_acceptance(application)
    return unless sendable?(application)
    accepted(application).deliver_now
  end

  def self.send_decline(application)
    return unless sendable?(application)
    declined(application).deliver_now
  end

  def self.sendable?(application)
    Features.email? && application.user.email.present?
  end

  def accepted(application)
    set_up(application)
    @message = @course.course_application_form&.acceptance_email
    mail(**addressing, subject: "Welcome to your #{@course.title} course!")
  end

  def declined(application)
    set_up(application)
    mail(**addressing, subject: "#{@course.title} update")
  end

  private

  def set_up(application)
    @course = application.course
    @user = application.user
    @name = @user.real_name.presence || @user.username
    @manager = SpecialUsers.scholars_and_scientists_manager
  end

  def addressing
    return { to: @user.email } if @manager&.email.blank?

    { to: @user.email, from: @manager.email, reply_to: @manager.email }
  end
end
