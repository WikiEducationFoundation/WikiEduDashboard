# == Schema Information
#
# Table name: weeks
#
#  id         :integer          not null, primary key
#  title      :string(255)
#  course_id  :integer
#  created_at :datetime
#  updated_at :datetime
#

#= Week model
class Week < ActiveRecord::Base
  belongs_to :course
  has_many :blocks
  has_many :gradeables, through: :blocks

  before_destroy :cleanup

  def cleanup
    blocks.destroy_all
  end
end
