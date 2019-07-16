# frozen_string_literal: true

json.user_profile do
  json.call(@user, :username, :profile_image)
end
