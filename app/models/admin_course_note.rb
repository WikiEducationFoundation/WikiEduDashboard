# frozen_string_literal: true

class AdminCourseNote < ApplicationRecord
  belongs_to :course, foreign_key: 'courses_id'

  validates :courses_id, presence: true
  validates :title, presence: true
  validates :text, presence: true
  validates :edited_by, presence: true

  def update_note(attributes)
    update(attributes.slice(:title, :text, :edited_by))
  end
end
