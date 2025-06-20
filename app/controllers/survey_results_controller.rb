# frozen_string_literal: true

class SurveyResultsController < SurveysController
  layout 'surveys'

  before_action :set_survey
  before_action :set_question_groups

  def results
    protect_confidentiality { return }
    respond_to do |format|
      format.html
      format.csv do
        filename = "#{@survey.name}-results#{Time.zone.today}.csv"
        send_data @survey.to_csv, filename:
      end
    end
  end

  private

  def set_question_groups
    super
    @survey_user_cache = {}
  end
end
