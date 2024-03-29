# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/commons"

#= Importer for data about files uploaded to Wikimedia Commons
class UploadImporter
  ################
  # Entry points #
  ################
  def self.import_uploads_for_current_users
    User.current.role('student').find_in_batches(batch_size: 100) do |batch|
      import_all_uploads batch
    end
  end

  def self.import_all_uploads(users)
    users.in_groups_of(50, false) do |user_batch|
      uploads = Commons.get_uploads user_batch
      import_uploads uploads
    end
  end

  def self.update_usage_count_by_course(courses)
    courses.each do |course|
      update_usage_count(course.uploads.where(deleted: false))
    end
  end

  def self.update_usage_count(commons_uploads, update_service: nil)
    commons_uploads.in_groups_of(50, false) do |file_batch|
      usages = Commons.get_usages(file_batch, update_service:)
      import_usages usages
    end
  end

  DAYS_TO_CHECK_FOR_DELETION = 100
  def self.find_deleted_files
    CommonsUpload.where(deleted: false)
                 .where('created_at > ?', DAYS_TO_CHECK_FOR_DELETION.days.ago)
                 .find_in_batches(batch_size: 50) do |file_batch|
      deleted_files = Commons.find_missing_files file_batch
      CommonsUpload.transaction do
        deleted_files.each { |file| file.update(deleted: true) }
      end
    end
  end

  def self.import_all_missing_urls
    CommonsUpload.where(thumburl: nil, deleted: false).find_in_batches do |batch|
      import_urls_in_batches(batch)
    end
  end

  ################
  # Data methods #
  ################
  def self.import_urls_in_batches(commons_uploads, update_service: nil)
    # Larger values (50) per batch choke the MediaWiki API on this query.
    commons_uploads.in_groups_of(10, false) do |file_batch|
      file_urls = Commons.get_urls(file_batch, update_service:)
      import_urls file_urls
    end
  end

  def self.import_uploads(uploads)
    ActiveRecord::Base.transaction do
      uploads.each do |file|
        import_upload(file)
      end
    end
  end

  def self.import_upload(file)
    uploaded_at = file['timestamp']
    file_name = file['title']
    user = User.find_by(username: file['user'])
    # If the file page was overwritten by a different user, the username may not
    # be in the database.
    return unless user
    id = file['pageid']
    upload = CommonsUpload.new(id:,
                               uploaded_at:,
                               file_name:,
                               user_id: user.id)
    upload.save unless CommonsUpload.exists?(id)
  # FIXME: Workaround for four-byte unicode characters in file titles,
  # until we fix the database to handle them.
  # https://github.com/WikiEducationFoundation/WikiEduDashboard/issues/1744
  rescue ActiveRecord::StatementInvalid => e
    Sentry.capture_exception e
    save_upload_with_invalid_characters(upload)
  end

  def self.save_upload_with_invalid_characters(upload)
    upload.file_name = CGI.escape upload.file_name
    upload.save
  end

  def self.import_usages(usages)
    file_ids = usages.map { |usage| usage['pageid'] }
    # Create a hash matching file_ids to usage counts, starting at zero.
    usage_counts = file_ids.uniq.index_with { |_id| 0 }

    usages.each do |usage|
      id = usage['pageid']
      # Do not count non-mainspace usages
      usage_count = usage['globalusage'].count { |u| u['ns'] == '0' }
      usage_counts[id] += usage_count
    end

    save_usage_counts(usage_counts)
  end

  def self.save_usage_counts(usage_counts)
    ActiveRecord::Base.transaction do
      usage_counts.each do |id, count|
        file = CommonsUpload.find(id)
        file.usage_count = count
        file.save
      end
    end
  end

  def self.import_urls(file_urls)
    ActiveRecord::Base.transaction do
      file_urls.each do |file_url|
        id = file_url['pageid']
        file = CommonsUpload.find(id)
        file.thumburl = file_url['imageinfo'][0]['thumburl']
        file.thumbwidth = file_url['imageinfo'][0]['thumbwidth']
        file.thumbheight = file_url['imageinfo'][0]['thumbheight']
        file.save
      end
    end
  end
end
