# frozen_string_literal: true

# == Schema Information
#
# Table name: backups
#
#  id           :bigint           not null, primary key
#  scheduled_at :datetime
#  start        :datetime
#  end          :datetime
#  status       :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

FactoryBot.define do
  factory :backup do
  end
end
