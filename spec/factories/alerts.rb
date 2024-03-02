# frozen_string_literal: true

# == Schema Information
#
# Table name: alerts
#
#  id             :integer          not null, primary key
#  course_id      :integer
#  user_id        :integer
#  article_id     :integer
#  revision_id    :integer
#  type           :string(255)
#  email_sent_at  :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  message        :text(65535)
#  target_user_id :integer
#  subject_id     :integer
#  resolved       :boolean          default(FALSE)
#  details        :text(65535)
#

FactoryBot.define do
  factory :alert, class: 'ArticlesForDeletionAlert'

  factory :add_ta_alert, class: 'NoTaEnrolledAlert'

  factory :active_course_alert, class: 'ActiveCourseAlert'

  factory :bad_work_alert, class: 'BadWorkAlert'

  factory :continued_course_activity_alert, class: 'ContinuedCourseActivityAlert'

  factory :overdue_training_alert, class: 'OverdueTrainingAlert'

  factory :onboarding_alert, class: 'OnboardingAlert'

  factory :unsubmitted_course_alert, class: 'UnsubmittedCourseAlert'
end
