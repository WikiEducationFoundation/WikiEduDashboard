# frozen_string_literal: true

FactoryBot.define do
  factory :course_note do
    title { 'Sample Note Title' }
    text { 'Sample Note Text' }
    edited_by { 'Sample User' }
    courses_id { association(:course).id }
  end
end
