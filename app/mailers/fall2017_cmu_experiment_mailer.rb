# frozen_string_literal: true

class Fall2017CmuExperimentMailer < ApplicationMailer
  def self.send_invitation(course, instructor, email_code)
    return unless Features.email?
    return if instructor.email.nil?
    email(course, instructor, email_code).deliver_now
  end

  def email(course, instructor, email_code)
    @course = course
    @instructor = instructor
    @opt_in_link = "/experiments/fall2017_cmu_experiment/#{@course.id}/#{email_code}/opt_in"
    @opt_out_link = "/experiments/fall2017_cmu_experiment/#{@course.id}/#{email_code}/opt_out"
    mail(to: @instructor.email,
         reply_to: 'robert.kraut@cmu.edu',
         subject: 'Wikipedia discussion service: please opt in')
  end
end
