# frozen_string_literal: true

json.user_profile do
  json.call(@user, :username, :profile_image)
  json.bio @user.user_profile&.bio
  json.location @user.user_profile&.location
  json.instution @user.user_profile&.institution
end
