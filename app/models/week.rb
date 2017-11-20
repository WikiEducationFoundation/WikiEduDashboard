# frozen_string_literal: true

# == Schema Information
#
# Table name: weeks
#
#  id         :integer          not null, primary key
#  title      :string(255)
#  course_id  :integer
#  created_at :datetime
#  updated_at :datetime
#  order      :integer          default(1), not null
#

#= Week model
class Week < ActiveRecord::Base
  belongs_to :course
  has_many :blocks, -> { order(:order) }, dependent: :destroy
  has_many :gradeables, through: :blocks

  def meeting_dates
    CourseMeetingsManager.new(course).meeting_dates_of(self)
  end
end
