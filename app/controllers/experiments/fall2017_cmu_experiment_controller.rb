# frozen_string_literal: true

require "#{Rails.root}/lib/experiments/fall2017_cmu_experiment"

module Experiments
  class Fall2017CmuExperimentController < ApplicationController
    before_action :set_course_and_check_email_code, only: %i[opt_in opt_out]
    before_action :require_admin_permissions, only: :course_list

    def opt_in
      Fall2017CmuExperiment.new(@course).opt_in
      flash[:notice] = 'Thank you for opting in. We will add the video sessions'\
                       ' to the relevant assignments on the timeline for your'\
                       ' WikiEd dashboard and send you an email about next steps.'
      redirect_to "/courses/#{@course.slug}"
    end

    def opt_out
      Fall2017CmuExperiment.new(@course).opt_out
      flash[:notice] = 'Okay, you have opted out.'
      redirect_to "/courses/#{@course.slug}"
    end

    def course_list
      send_data Fall2017CmuExperiment.course_list,
                filename: "fall2017-cmu-experiment-courses-#{Time.zone.today}.csv"
    end

    private

    def set_course_and_check_email_code
      @course = Course.find(params[:course_id])
      code = @course.flags[Fall2017CmuExperiment::EMAIL_CODE]
      raise IncorrectEmailCodeError if code.nil?
      raise IncorrectEmailCodeError unless code == params[:email_code]
    end
  end

  class IncorrectEmailCodeError < StandardError; end
end
