# frozen_string_literal: true

json.array!(@surveys) do |survey|
  json.extract! survey, :id, :name
  json.url survey_url(survey, format: :json)
end
