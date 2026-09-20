# frozen_string_literal: true

FactoryBot.define do
  factory :institution do
    sequence(:name) { |n| "University #{n}" }
  end
end
