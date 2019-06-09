# frozen_string_literal: true

class CourseWiki < ApplicationRecord
  belongs_to :course
  belongs_to :wiki
end
