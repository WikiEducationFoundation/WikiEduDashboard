json.uploads @course.uploads do |up|
  json.(up, :id, :uploaded_at, :usage_count, :url, :thumburl)
  json.file_name pretty_filename(up)
  json.url up.url
  json.uploader up.user.wiki_id
end