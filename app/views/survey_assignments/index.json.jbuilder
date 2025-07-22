# frozen_string_literal: true

json.array!(@survey_assignments) do |survey_assignment|
  json.extract! survey_assignment, :id
  json.url survey_assignment_url(survey_assignment, format: :json)
end
