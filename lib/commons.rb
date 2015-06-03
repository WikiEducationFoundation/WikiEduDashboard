require 'mediawiki_api'
require 'json'

#= This class is for getting data directly from the Wikimedia Commons API.
class Commons
  ###################
  # Request methods #
  ###################

  # Get user contribution data that corresponds to new file uploads.
  def self.get_uploads(users)
    upload_query = build_upload_query users
    uploads = []

    continue = true
    until continue.nil?
      response = api_get(upload_query)
      uploads += response.data['usercontribs']
      continue = response['continue'] # nil if there is no continue
      upload_query['uccontinue'] = continue['uccontinue'] if continue
    end

    uploads
  end

  # Get data about how files are being used across Wikimedia sites.
  def self.get_usages(commons_uploads)
    usage_query = build_usage_query commons_uploads
    usages = []

    continue = true
    until continue.nil?
      response = api_get(usage_query)
      results = response.data['pages']
      # Account for the different format returned when only a single, missing
      # page is queried, which looks like: [{"pageid"=>0, "missing"=>""}]
      results = results.values unless results.is_a?(Array)
      results.each do |r|
        usages << r unless r['globalusage'].blank?
      end
      continue = response['continue'] # nil if there is no continue
      usage_query['gucontinue'] = continue['gucontinue'] if continue
    end

    usages
  end

  def self.get_urls(commons_uploads)
    url_query = build_url_query commons_uploads
    file_urls = []

    continue = true
    until continue.nil?
      response = api_get(url_query)
      results = response.data['pages']
      # Account for the different format returned when only a single, missing
      # page is queried, which looks like: [{"pageid"=>0, "missing"=>""}]
      results = results.values unless results.is_a?(Array)
      results.each do |r|
        file_urls << r unless r['imageinfo'].blank?
      end
      continue = response['continue'] # nil if there is no continue
      url_query['iicontinue'] = continue['iicontinue'] if continue
    end

    file_urls
  end
  ##################
  # Helper methods #
  ##################
  def self.build_upload_query(users)
    usernames = users.map(&:wiki_id)
    upload_query = { list: 'usercontribs',
                     ucuser: usernames,
                     ucnamespace: 6, # File: namespace
                     ucshow: 'new', # New pages ~= new uploads
                     uclimit: 500, # 500 is max for non-bots
                     continue: ''
                   }
    upload_query
  end

  def self.build_usage_query(commons_uploads)
    file_ids = commons_uploads.map(&:id)
    usage_query = { prop: 'globalusage',
                    pageids: file_ids,
                    gulimit: 500, # 500 is max for non-bots
                    gufilterlocal: 'true', # Don't return local Commons usage
                    continue: ''
                  }
    usage_query
  end

  def self.build_url_query(commons_uploads)
    file_ids = commons_uploads.map(&:id)
    url_query = { prop: 'imageinfo',
                  iiprop: 'url',
                  iiurlheight: 480,
                  pageids: file_ids,
                  iilimit: 50, # 50 is max when iiurlheight is used.
                  continue: ''
                }
    url_query
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

    def api_get(query)
      tries ||= 3
      commons.query query
    rescue StandardError => e
      tries -= 1
      typical_errors = [Faraday::TimeoutError]
      retry if typical_errors.include?(e.class) && tries >= 0
      raise e
    end
  end
end
