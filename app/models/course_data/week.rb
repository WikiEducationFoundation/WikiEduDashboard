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
  # inverse_of is needed because the order scope turns off automatic inverse
  # detection. With it, block.week is this Week, so block due dates reach the
  # course's memoized meetings manager instead of each building their own.
  has_many :blocks, -> { order(:order) }, dependent: :destroy, inverse_of: :week

  def meeting_dates
    course.meetings_manager.meeting_dates_of(self)
  end
end
