# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/data_cycle/survey_update"

class SurveyUpdateWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed

  def perform
    SurveyUpdate.new
  end
end
