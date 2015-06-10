json.uploads @course.uploads do |up|
  json.(up, :id, :uploaded_at, :usage_count, :url, :thumburl)
  json.url up.url
  json.file_name pretty_filename(up)
  json.uploader up.user.wiki_id
end