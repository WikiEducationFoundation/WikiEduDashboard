# Tags are administrative information, and are not shown unless the user is an admin.
json.tags []

return unless current_user && current_user.admin?

json.tags course.tags do |tag|
  json.call(tag, :id, :tag, :key)
end
