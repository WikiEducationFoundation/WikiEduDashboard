# frozen_string_literal: true

# == Schema Information
#
# Table name: survey_assignments
#
#  id                                      :integer          not null, primary key
#  courses_user_role                       :integer
#  created_at                              :datetime         not null
#  updated_at                              :datetime         not null
#  send_date_days                          :integer
#  survey_id                               :integer
#  send_before                             :boolean          default(TRUE)
#  send_date_relative_to                   :string(255)
#  published                               :boolean          default(FALSE)
#  notes                                   :text(65535)
#  follow_up_days_after_first_notification :integer
#  send_email                              :boolean
#  email_template                          :string(255)
#  custom_email                            :text(65535)
#

FactoryBot.define do
  factory :survey_assignment do
  end
end
