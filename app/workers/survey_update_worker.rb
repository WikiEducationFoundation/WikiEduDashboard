# frozen_string_literal: true
require_dependency Rails.root.join('lib/data_cycle/survey_update')

class SurveyUpdateWorker
  include Sidekiq::Worker

  def perform
    SurveyUpdate.new
  end
end
