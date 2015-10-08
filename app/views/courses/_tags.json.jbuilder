json.tags course.tags do |tag|
  json.call(tag, :id, :tag, :key)
end
