#= Assignment model
class Assignment < ActiveRecord::Base
  belongs_to :user
  belongs_to :course
  belongs_to :article

  has_many :assignments_users, class_name: AssignmentsUsers
  has_many :reviewers, -> { uniq }, through: :assignments_users, source: :user
end
