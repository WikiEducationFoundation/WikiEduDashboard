# frozen_string_literal: true

json.course do
  json.categories @course.categories.includes(:wiki) do |cat|
    json.call(cat, :id, :name, :depth, :wiki)
  end
end
