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
    usages = get_image_data(usage_query, 'globalusage', 'gucontinue')
    usages
  end

  def self.get_urls(commons_uploads)
    url_query = build_url_query commons_uploads
    file_urls = get_image_data(url_query, 'imageinfo', 'iicontinue')
    file_urls
  end
  ##################
  # Helper methods #
  ##################
  def self.get_image_data(query, prop, continue_param)
    image_data = []

    continue = true
    until continue.nil?
      response = api_get(query)
      return image_data if response.blank?
      results = response.data['pages']
      # Account for the different format returned when only a single, missing
      # page is queried, which looks like: [{"pageid"=>0, "missing"=>""}]
      results = results.values unless results.is_a?(Array)
      results.each do |r|
        image_data << r unless r[prop].blank?
      end
      continue = response['continue'] # nil if there is no continue
      query[continue_param] = continue[continue_param] if continue
    end

    image_data
  end

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
    rescue MediawikiApi::ApiError => e
      handle_api_error e, query
    rescue StandardError => e
      tries -= 1
      typical_errors = [Faraday::TimeoutError,
                        Faraday::ConnectionFailed]
      retry if typical_errors.include?(e.class) && tries >= 0
      raise e
    end

    def handle_api_error(e, query)
      # This general means the file is not an image, so it has no thumbnail.
      if e.code == 'iiurlparamnormal'
        # We need to extract the filename from an info value that looks like:
        # "Could not normalise image parameters for Jewish_Encyclopedia_Volume_6.pdf"
        info = e.info
        info['Could not normalise image parameters for '] = ''
        bad_file_name = ('File:' + info).gsub('_',' ')
        file = CommonsUpload.find_by(file_name: bad_file_name)
        # TODO: implement CommonsUpload#not_an_image to mark files that won't have a thumburl
        # TODO: exclude such files from the url batch
        # file.not_an_image
        Rails.logger.debug "Caught iiurlparamnormal error: #{bad_file_name}"
        query[:pageids] -= [file.id]
        api_get(query) unless query[:pageids].empty?
      else
        raise e
      end
    end
  end
end
