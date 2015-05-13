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
