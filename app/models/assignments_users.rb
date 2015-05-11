#= Used for associating assignments with reviewers
class AssignmentsUsers < ActiveRecord::Base
  belongs_to :assignment
  belongs_to :user
end
