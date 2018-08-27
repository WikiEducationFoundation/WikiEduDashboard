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

require 'rails_helper'

RSpec.describe QuestionGroupConditional, type: :model do
  describe 'association' do
    it { is_expected.to belong_to(:rapidfire_question_group) }
    it { is_expected.to belong_to(:campaign) }
  end
end
