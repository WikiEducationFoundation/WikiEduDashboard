# frozen_string_literal: true

FactoryBot.define do
  factory :facilitator_stat do
    snapshot_date { Time.zone.today }
    association :user
    total_programs_count { 3 }
    active_programs_count { 1 }
    total_edits { 500 }
    new_editors_count { 20 }
    new_editors_count_with_preregistration { 25 }
    total_students_count { 45 }
    total_characters_added { 50_000 }
    active_in_last_year { true }
  end
end
