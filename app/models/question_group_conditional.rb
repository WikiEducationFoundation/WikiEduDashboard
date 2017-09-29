# frozen_string_literal: true

# == Schema Information
#
# Table name: question_group_conditionals
#
#  id                          :integer          not null, primary key
#  rapidfire_question_group_id :integer
#  campaign_id                 :integer
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#

class QuestionGroupConditional < ActiveRecord::Base
  belongs_to :rapidfire_question_group, class_name: 'Rapidfire::QuestionGroup'
  belongs_to :campaign
end
