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

class CoursesWikis < ApplicationRecord
  validates :wiki_id, uniqueness: { scope: :course_id }

  belongs_to :course
  belongs_to :wiki
  has_many :courses_namespaces, class_name: 'CoursesNamespaces', dependent: :destroy
  
  def update_namespaces(updated_ns)
    update(courses_namespaces: updated_ns)
  end
end
