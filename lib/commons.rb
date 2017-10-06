# frozen_string_literal: true

require 'mediawiki_api'
require 'json'

#= This class is for getting data directly from the Wikimedia Commons API.
class Commons
  def initialize(query)
    @query = query
  end
  ###################
  # Request methods #
  ###################

  # Get user contribution data that corresponds to new file uploads.
  def self.get_uploads(users)
    upload_query = build_upload_query users
    uploads = new(upload_query).fetch_all_uploads
    uploads
  end

  # Get data about how files are being used across Wikimedia sites.
  def self.get_usages(commons_uploads)
    usage_query = build_usage_query commons_uploads
    usages = new(usage_query).get_image_data('globalusage', 'gucontinue')
    usages
  end

  def self.find_missing_files(commons_uploads)
    missing_query = build_info_query(commons_uploads)
    pages = new(missing_query).get_image_data('pageid', '')
    missing_pages = pages.select { |page| page['missing'] }
    missing_page_ids = missing_pages.map { |page| page['pageid'] }
    commons_uploads.select { |file| missing_page_ids.include? file.id }
  end

  def self.get_urls(commons_uploads)
    url_query = build_url_query commons_uploads
    file_urls = new(url_query).get_image_data('imageinfo', 'iicontinue')
    file_urls
  end

  ##################
  # Query builders #
  ##################

  def self.build_upload_query(users)
    usernames = users.map(&:username)
    upload_query = { list: 'usercontribs',
                     ucuser: usernames,
                     ucnamespace: 6, # File: namespace
                     ucshow: 'new', # New pages ~= new uploads
                     uclimit: 500, # 500 is max for non-bots
                     continue: '' }
    upload_query
  end

  def self.build_usage_query(commons_uploads)
    file_ids = commons_uploads.map(&:id)
    usage_query = { prop: 'globalusage',
                    pageids: file_ids,
                    gulimit: 500, # 500 is max for non-bots
                    gufilterlocal: 'true', # Don't return local Commons usage
                    guprop: 'namespace', # Fetch NS for each usage
                    continue: '' }
    usage_query
  end

  def self.build_info_query(commons_uploads)
    file_ids = commons_uploads.map(&:id)
    info_query = { pageids: file_ids,
                   continue: '' }
    info_query
  end

  def self.build_url_query(commons_uploads)
    file_ids = commons_uploads.map(&:id)
    url_query = { prop: 'imageinfo',
                  iiprop: 'url',
                  iiurlheight: 480,
                  pageids: file_ids,
                  iilimit: 50, # 50 is max when iiurlheight is used.
                  continue: '' }
    url_query
  end

  ##########################
  # Instance query methods #
  ##########################

  def fetch_all_uploads
    @uploads = []
    @continue = true
    until @continue.nil?
      response = api_get
      return @uploads unless response # fall back gracefully if the query fails
      @uploads += response.data['usercontribs']
      @continue = response['continue'] # nil if there is no continue
      @query['uccontinue'] = @continue['uccontinue'] if @continue
    end

    @uploads
  end

  def get_image_data(prop, continue_param)
    @continue_param = continue_param
    @prop = prop

    @image_data = []
    @continue = true
    until @continue.nil?
      response = api_get
      return @image_data if response.blank?
      parse_image_data_and_update_continue(response)
    end
    @image_data
  end

  def parse_image_data_and_update_continue(response)
    results = response.data['pages']
    # Account for the different format returned when only a single, missing
    # page is queried, which looks like: [{"pageid"=>0, "missing"=>""}]
    results = results.values unless results.is_a?(Array)
    results.each do |r|
      @image_data << r unless r[@prop].blank?
    end
    @continue = response['continue'] # nil if there is no continue
    @query[@continue_param] = @continue[@continue_param] if @continue
  end

  ###################
  # Private methods #
  ###################
  private

  def api_get
    WikiApi.new(CommonsWiki.new).query(@query)
  end
end
