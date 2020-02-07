# frozen_string_literal: true

json.course do
  page = @page&.positive? ? @page : 1
  per_page = @page&.positive? ? 8 : @course.uploads.includes(:user).count
  json.uploads @course.uploads.includes(:user).paginate(page: page, per_page: per_page) do |upload|
    json.call(upload, :id, :uploaded_at, :usage_count, :url, :thumburl, :deleted,
              :thumbwidth, :thumbheight)
    json.file_name pretty_filename(upload)
    json.uploader upload.user.username
  end
end
