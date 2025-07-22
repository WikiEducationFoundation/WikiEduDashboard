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

FactoryBot.define do
  factory :question_group_conditional do
  end
end
