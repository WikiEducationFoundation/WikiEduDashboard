# frozen_string_literal: true

# == Schema Information
#
# Table name: assignment_suggestions
#
#  id            :integer          not null, primary key
#  text          :text(65535)
#  assignment_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  user_id       :integer
#

FactoryBot.define do
  factory :assignment_suggestion do
    text 'Improve this article'
  end
end
