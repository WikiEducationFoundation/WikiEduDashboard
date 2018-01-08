# frozen_string_literal: true
require "#{Rails.root}/lib/experiments/spring2018_cmu_experiment"

class ExperimentsPresenter
  def initialize(course)
    @course = course
  end

  ACTIVE_EXPERIMENTS = [Spring2018CmuExperiment].freeze
  def experiment
    @experiment ||= ACTIVE_EXPERIMENTS.find do |exp|
      @course.flags[exp::STATUS_KEY] == 'email_sent'
    end
  end

  def notification
    {
      message: 'Would you like to opt in to our research collaboration with Carnegie Mellon University?',
      read_more: 'Read more here.',
      read_more_link: 'http://kraut.hciresearch.org/sites/kraut.hciresearch.org/files/open/WP-Instructor-ConsentForm-v3.pdf',
      opt_in_link: opt_in_link,
      opt_out_link: opt_out_link
    }
  end

  def opt_in_link
    "/experiments/#{experiment.name.underscore}/#{@course.id}/#{code}/opt_in"
  end

  def opt_out_link
    "/experiments/#{experiment.name.underscore}/#{@course.id}/#{code}/opt_out"
  end

  def code
    @code ||= @course.flags[experiment::EMAIL_CODE]
  end
end
