json.tags course.tags do |tag|
  json.(tag, :id, :tag, :key)
end
