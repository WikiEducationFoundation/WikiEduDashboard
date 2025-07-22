# frozen_string_literal: true

json.course do
  json.partial! 'courses/campaigns', course: @course
end
