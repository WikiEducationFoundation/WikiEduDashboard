# frozen_string_literal: true

json.blocks blocks.each do |block|
  json.partial! 'courses/block', block: block, course: course
end
