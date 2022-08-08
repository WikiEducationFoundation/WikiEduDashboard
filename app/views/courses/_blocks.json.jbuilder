# frozen_string_literal: true

user ||= current_user
json.blocks blocks.each do |block|
  json.partial! 'courses/block', block:, course:, user:
end
