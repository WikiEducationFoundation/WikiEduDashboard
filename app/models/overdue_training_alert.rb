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

# Alert for when a student has an assigned training that is overdue
class OverdueTrainingAlert < Alert
  def main_subject
    "#{user.username} / #{course.slug}"
  end

  def url
    "https://#{ENV['dashboard_url']}/training/students/#{training_module_slug}"
  end

  def opt_out_link
    "https://#{ENV['dashboard_url']}/update_email_preferences/#{user.username}#{opt_out_params}"
  end

  def send_email
    return if emails_disabled?
    return if opted_out?
    # send
  end

  private

  def opted_out?
    user_profile.email_allowed?('OverdueTrainingAlert')
  end

  def opt_out_params
    "?type=OverdueTrainingAlert&token=#{user_profile.email_preferences_token}"
  end

  def user_profile
    user.user_profile || user.create_user_profile
  end

  def training_module_slug
    details[:training_module_slug]
  end
end
