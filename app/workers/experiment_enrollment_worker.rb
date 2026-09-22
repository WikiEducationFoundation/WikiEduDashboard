# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/experiments/opt_in_experiment"

# Notifies an opt-in experiment's external data collection server, if it has
# one, that a student has opted in. See OptInExperiment#report_enrollment.
class ExperimentEnrollmentWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def self.schedule(experiment_courses_user)
    perform_async(experiment_courses_user.id)
  end

  def perform(experiment_courses_user_id)
    record = ExperimentCoursesUser.find_by(id: experiment_courses_user_id)
    return unless record&.opted_in?

    OptInExperiment.find(record.experiment_slug)&.report_enrollment(record)
  end
end
