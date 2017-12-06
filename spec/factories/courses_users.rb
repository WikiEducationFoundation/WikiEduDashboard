# frozen_string_literal: true
# == Schema Information
#
# Table name: courses_users
#
#  id                     :integer          not null, primary key
#  created_at             :datetime
#  updated_at             :datetime
#  course_id              :integer
#  user_id                :integer
#  character_sum_ms       :integer          default(0)
#  character_sum_us       :integer          default(0)
#  revision_count         :integer          default(0)
#  assigned_article_title :string(255)
#  role                   :integer          default(0)
#  recent_revisions       :integer          default(0)
#  character_sum_draft    :integer          default(0)
#  real_name              :string(255)
#  role_description       :string(255)
#

FactoryBot.define do
  factory :courses_user, class: 'CoursesUsers' do
    nil
  end
end
