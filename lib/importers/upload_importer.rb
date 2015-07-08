require "#{Rails.root}/lib/commons"

#= Importer for data about files uploaded to Wikimedia Commons
class UploadImporter
  ################
  # Entry points #
  ################
  def self.import_all_uploads(users)
    Utils.chunk_requests(users) do |user_batch|
      uploads = Commons.get_uploads user_batch
      import_uploads uploads
    end
  end

  def self.update_usage_count(commons_uploads)
    Utils.chunk_requests(commons_uploads) do |file_batch|
      usages = Commons.get_usages file_batch
      import_usages usages
    end
  end

  def self.import_urls_in_batches(commons_uploads)
    # Larger values (50) per batch choke the MediaWiki API on this query.
    Utils.chunk_requests(commons_uploads, 10) do |file_batch|
      file_urls = Commons.get_urls file_batch
      import_urls file_urls
    end
  end
  ###################
  # Parsing methods #
  ###################
  def self.import_uploads(uploads)
    ActiveRecord::Base.transaction do
      uploads.each do |file|
        uploaded_at = file['timestamp']
        file_name = file['title']
        username = file['user']
        user_id = User.find_by(wiki_id: username).id
        id = file['pageid']
        upload = CommonsUpload.new(id: id,
                                   uploaded_at: uploaded_at,
                                   file_name: file_name,
                                   user_id: user_id)
        upload.save unless CommonsUpload.exists?(id)
      end
    end
  end

  def self.import_usages(usages)
    file_ids = usages.map { |usage| usage['pageid'] }
    # Create a hash matching file_ids to usage counts, starting at zero.
    usage_counts = Hash[file_ids.uniq.map { |id| [id, 0] }]

    usages.each do |usage|
      id = usage['pageid']
      # Do not count non-mainspace usages
      usage_count = usage['globalusage'].count { |u| u['ns'] == '0' }
      usage_counts[id] += usage_count
    end

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
