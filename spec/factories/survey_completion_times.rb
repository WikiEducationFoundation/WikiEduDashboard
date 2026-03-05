# frozen_string_literal: true

FactoryBot.define do
  factory :survey_completion_time do
    association :survey
    association :user
    started_at { 10.minutes.ago }
  end
end
