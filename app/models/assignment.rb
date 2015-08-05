# == Schema Information
#
# Table name: assignments
#
#  id            :integer          not null, primary key
#  created_at    :datetime
#  updated_at    :datetime
#  user_id       :integer
#  course_id     :integer
#  article_id    :integer
#  article_title :string(255)
#  role          :integer
#

#= Assignment model
class Assignment < ActiveRecord::Base
  belongs_to :user
  belongs_to :course
  belongs_to :article

  scope :assigned, -> { where(role: 0) }
  scope :reviewing, -> { where(role: 1) }
end
