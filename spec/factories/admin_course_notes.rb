# frozen_string_literal: true

FactoryBot.define do
  factory :admin_course_note do
    title { 'Sample Note Title' }
    text { 'Sample Note Text' }
    edited_by { 'Sample User' }
    association :course
  end
end
