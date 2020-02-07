# frozen_string_literal: true

json.course do
  page = @page&.positive? ? @page : 1
  per_page = if @page&.positive?
               @per_page&.positive? ? @per_page : 10
             else
               @course.uploads.includes(:user).count
             end
  json.uploads @course.uploads.includes(:user).paginate(page: page, per_page: per_page) do |upload|
    json.call(upload, :id, :uploaded_at, :usage_count, :url, :thumburl, :deleted,
              :thumbwidth, :thumbheight)
    json.file_name pretty_filename(upload)
    json.uploader upload.user.username
  end
end
