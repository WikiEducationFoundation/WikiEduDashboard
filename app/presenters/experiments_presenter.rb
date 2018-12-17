# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/experiments/spring2018_cmu_experiment"

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
      message: 'Would you like to add our latest peer discussion service to help your students '\
      'with their assignment?',
      read_more: 'Read more here.',
      read_more_link: 'https://wikiedu.org/intertwine-research-collaboration/',
      opt_in_link: opt_in_link,
      opt_out_link: opt_out_link
    }
  end

  private

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
