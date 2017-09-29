# frozen_string_literal: true

json.course do
  json.uploads @course.uploads.includes(:user) do |upload|
    json.call(upload, :id, :uploaded_at, :usage_count, :url, :thumburl, :deleted)
    json.url upload.url
    json.file_name pretty_filename(upload)
    json.uploader upload.user.username
  end
end
