# frozen_string_literal: true

json.user do
  json.username current_user.username
end

json.current_courses @pres.current
