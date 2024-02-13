# frozen_string_literal: true

class CourseNote < ApplicationRecord
  belongs_to :course, foreign_key: 'courses_id'

  validates :courses_id, presence: true
  validates :title, presence: true
  validates :text, presence: true
  validates :edited_by, presence: true

  def create_new_note(attributes)
    self.attributes = attributes
    if save
      self
    else
      false
    end
  end

  def update_note(attributes)
    update(attributes.slice(:title, :text, :edited_by))
  end
end
