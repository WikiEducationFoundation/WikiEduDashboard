# frozen_string_literal: true
# == Schema Information
#
# Table name: categories_courses
#
#  id          :bigint           not null, primary key
#  category_id :integer
#  course_id   :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

FactoryBot.define do
  factory :categories_courses, class: 'CategoriesCourses' do
    nil
  end
end
