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
class Week < ApplicationRecord
  belongs_to :course
  has_many :blocks, -> { order(:order) }, dependent: :destroy

  def meeting_dates
    course.meetings_manager.meeting_dates_of(self)
  end
end
