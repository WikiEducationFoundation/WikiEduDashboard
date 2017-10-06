# frozen_string_literal: true

# == Schema Information
#
# Table name: campaigns_courses
#
#  id          :integer          not null, primary key
#  campaign_id :integer
#  course_id   :integer
#  created_at  :datetime
#  updated_at  :datetime
#

#= Campaign + Course join model
class CampaignsCourses < ActiveRecord::Base
  belongs_to :campaign
  belongs_to :course
end
