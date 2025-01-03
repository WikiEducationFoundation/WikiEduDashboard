# frozen_string_literal: true

class Spring2018CmuExperimentMailer < ApplicationMailer
  def self.send_invitation(course, instructor, email_code, reminder: false)
    return unless Features.email?
    return if instructor.email.nil?
    email(course, instructor, email_code, reminder:).deliver_now
  end

  def email(course, instructor, email_code, reminder: false)
    @course = course
    @instructor = instructor
    subject = 'Peer support for students in your Wikipedia assignment'
    subject = "Reminder: #{subject}" if reminder
    @opt_in_link = "https://#{ENV['dashboard_url']}/experiments/spring2018_cmu_experiment/"\
                   "#{@course.id}/#{email_code}/opt_in"
    @opt_out_link = "https://#{ENV['dashboard_url']}/experiments/spring2018_cmu_experiment/"\
                    "#{@course.id}/#{email_code}/opt_out"
    mail(to: @instructor.email,
         reply_to: 'robert.kraut@cmu.edu',
         subject:)
  end
end
