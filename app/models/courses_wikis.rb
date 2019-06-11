# frozen_string_literal: true

class CoursesWikis < ApplicationRecord
  belongs_to :course
  belongs_to :wiki
end
