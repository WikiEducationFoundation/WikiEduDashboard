# frozen_string_literal: true

json.user do
  json.call(@user, :username, :real_name, :email, :created_at, :updated_at, :locale, :first_login)
  if @user.user_profile
    json.call(@user.user_profile, :bio, :image_file_name, :image_file_link, :image_updated_at,
              :location, :institution, :email_preferences)
  end
end

json.courses do
  json.array! @user.courses_users.includes(:course).each do |course_user|
    json.course course_user.course.slug
    json.call(course_user, :role, :real_name, :role_description, :character_sum_ms,
              :character_sum_us, :character_sum_draft, :revision_count, :references_count,
              :recent_revisions)
    json.enrolled_at course_user.created_at
    json.assigned do
      json.array! course_user.assignments.each do |assignment|
        json.call(assignment, :article_title, :article_url, :role, :created_at, :sandbox_url)
      end
    end
  end
end

json.campaigns do
  json.array! @user.campaigns_users.includes(:campaign).each do |campaign_user|
    json.campaign campaign_user.campaign.slug
    json.joined_at campaign_user.created_at
  end
end
