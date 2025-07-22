# frozen_string_literal: true

# == Schema Information
#
# Table name: courses_wikis
#
#  id         :bigint           not null, primary key
#  course_id  :integer
#  wiki_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :courses_wikis do
  end
end
