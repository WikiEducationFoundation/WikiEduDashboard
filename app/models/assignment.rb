#= Assignment model
class Assignment < ActiveRecord::Base
  belongs_to :user
  belongs_to :course
  belongs_to :article

  scope :assigned, -> { where(role: 0) }
  scope :reviewing, -> { where(role: 1) }
end
