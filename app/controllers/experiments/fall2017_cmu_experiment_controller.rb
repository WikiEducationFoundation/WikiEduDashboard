# frozen_string_literal: true

require "#{Rails.root}/lib/experiments/fall2017_cmu_experiment"

module Experiments
  class Fall2017CmuExperimentController < ApplicationController
    before_action :set_course_and_check_email_code

    def opt_in
      Fall2017CmuExperiment.new(@course).opt_in
      flash[:notice] = 'Thanks for opting in!'
      redirect_to "/courses/#{@course.slug}"
    end

    def opt_out
      Fall2017CmuExperiment.new(@course).opt_out
      flash[:notice] = 'Okay, you have opted out.'
      redirect_to "/courses/#{@course.slug}"
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
