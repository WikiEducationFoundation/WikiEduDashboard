# frozen_string_literal: true

class CoursesWikis < ApplicationRecord
  validates :wiki_id, uniqueness: { scope: :course_id }

  belongs_to :course
  belongs_to :wiki
end
