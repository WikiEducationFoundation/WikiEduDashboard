json.course do
  json.uploads @course.uploads do |upload|
    json.call(upload, :id, :uploaded_at, :usage_count, :url, :thumburl)
    json.url upload.url
    json.file_name pretty_filename(upload)
    json.uploader upload.user.username
  end
end
