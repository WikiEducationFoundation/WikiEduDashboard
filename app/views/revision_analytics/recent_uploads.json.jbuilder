# frozen_string_literal: true

json.uploads @uploads do |upload|
  json.call(upload, :id, :uploaded_at, :usage_count, :url, :thumburl)
  json.url upload.url
  json.file_name pretty_filename(upload)
  json.uploader upload.user.username
end
