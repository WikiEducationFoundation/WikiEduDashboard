# frozen_string_literal: true
# == Schema Information
#
# Table name: retention_stats
#
#  id                   :bigint           not null, primary key
#  course_id            :integer          not null
#  user_id              :integer          not null
#  sessions_during      :integer          default(0), not null
#  days_to_return       :integer
#  sessions_after       :integer
#  edits_60_90          :integer
#  prior_edit_count     :integer          default(0), not null
#  long_term_wikipedian :boolean          default(FALSE), not null
#  prior_course_count   :integer          default(0), not null
#  computed_at          :datetime         not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#

FactoryBot.define do
  factory :retention_stat do
    course
    user
    sessions_during { 0 }
    prior_edit_count { 0 }
    long_term_wikipedian { false }
    prior_course_count { 0 }
    computed_at { Time.zone.now }
  end
end
