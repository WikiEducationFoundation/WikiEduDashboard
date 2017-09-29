# frozen_string_literal: true

# == Schema Information
#
# Table name: tags
#
#  id         :integer          not null, primary key
#  course_id  :integer
#  tag        :string(255)
#  key        :string(255)
#  created_at :datetime
#  updated_at :datetime
#

#= Tag model
class Tag < ActiveRecord::Base
  belongs_to :course
end
