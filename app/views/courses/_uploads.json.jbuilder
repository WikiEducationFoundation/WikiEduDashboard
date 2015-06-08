json.uploads @course.uploads do |up|
  json.(up, :id, :file_name, :uploaded_at, :usage_count, :thumburl)
  json.uploader_id up.user.wiki_id
end