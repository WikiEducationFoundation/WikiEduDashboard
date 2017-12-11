# == Schema Information
#
# Table name: categories_courses
#
#  id          :integer          not null, primary key
#  category_id :integer
#  course_id   :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class CategoriesCourses < ApplicationRecord
  belongs_to :category
  belongs_to :course
end
