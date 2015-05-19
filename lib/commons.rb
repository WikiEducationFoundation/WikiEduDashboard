require 'mediawiki_api'
require 'json'

# https://commons.wikimedia.org/w/api.php?action=query&list=usercontribs&ucuser=Ragesoss&ucnamespace=6&continue=&ucshow=new
#= This class is for getting data directly from the Wikimedia Commons API.
class Commons

  ###################
  # Parsing methods #
  ###################




  ###################
  # Request methods #
  ###################

  def self.import_all_uploads(users=nil)
    users ||= User.all
    Utils.chunk_requests(users) do |user_batch|
      uploads = get_uploads(user_batch)
      import_uploads(uploads)
    end
  end

  def self.update_file_usage
    # TODO: batching of queries
    CommonsUpload.all.each do |file|
      file_name = file.file_name
      file.usage_count = get_file_usage_count(file_name)
      file.save
    end
  end

  def self.get_uploads(users)
    usernames = users.map { |user| user.wiki_id }
    uploads = []
    upload_query = { list: 'usercontribs',
                     ucuser: usernames,
                     ucnamespace: 6, # File: namespace
                     ucshow: 'new', # New pages ~= new uploads
                     uclimit: 500, # 500 is max for non-bots
                     continue: ''
                   }

    continue = true
    until continue.nil?
      response = commons.query upload_query
      # TODO: handle network errors
      uploads += response.data['usercontribs']
      body = JSON.parse(response.to_json)['response']['body']
      continue = JSON.parse(body)['continue'] # nil if there is no continue
      upload_query['uccontinue'] = continue['uccontinue'] if continue
    end

    uploads
  end

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

  def self.update_usage_count(commons_uploads=nil)
    commons_uploads ||= CommonsUpload.all
    Utils.chunk_requests(commons_uploads) do |file_batch|
      usages = get_usages(file_batch)
      import_usages(usages)
    end
  end

  def self.get_usages(commons_uploads)
    file_ids = commons_uploads.map(&:id)
    usages = []
    usage_query = { prop: 'globalusage',
                    pageids: file_ids,
                    gulimit: 500, # 500 is max for non-bots
                    gufilterlocal: 'true', # Don't return local Commons usage
                    continue: ''
                  }

    continue = true
    until continue.nil?
      response = commons.query usage_query
      # TODO: handle network errors
      results =  response.data['pages'].values
      results.each do |r|
        usages << r unless r['globalusage'].empty?
      end
      body = JSON.parse(response.to_json)['response']['body']
      continue = JSON.parse(body)['continue'] # nil if there is no continue
      usage_query['gucontinue'] = continue['gucontinue'] if continue
    end

    usages
  end

  def self.import_usages(usages)
    file_ids = usages.map { |usage| usage['pageid'] }
    # Create a hash matching file_ids to usage counts, starting at zero.
    usage_counts = Hash[file_ids.uniq.map { |id| [id, 0] }]

    usages.each do |usage|
      id = usage['pageid']
      usage_count = usage['globalusage'].count
      usage_counts[id] += usage_count
    end

    pp usage_counts
    ActiveRecord::Base.transaction do
      usage_counts.each do |id, count|
        file = CommonsUpload.find(id)
        file.usage_count = count
        file.save
      end
    end
  end
  ###################
  # Private methods #
  ###################
  class << self
    private

    def commons
      url = 'https://commons.wikimedia.org/w/api.php'
      @commons = MediawikiApi::Client.new url
      @commons
    end
  end
end
