class CourseWiki < ApplicationRecord
  belongs_to :course
  belongs_to :wiki
end
