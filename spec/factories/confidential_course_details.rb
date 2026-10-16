# frozen_string_literal: true

FactoryBot.define do
  factory :confidential_course_detail do
    sequence(:sequence) { |n| n }
    real_title { 'Ųnderwater básket-weaving' }
    real_school { 'WÏNTR' }
    association :course
  end
end
