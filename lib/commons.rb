# frozen_string_literal: true

require 'json'
require_dependency "#{Rails.root}/lib/wiki_api"

#= This class is for getting data directly from the Wikimedia Commons API.
class Commons
  def initialize(query, update_service = nil)
    @query = query
    @update_service = update_service
  end
  ###################
  # Request methods #
  ###################

  # Get user contribution data that corresponds to new file uploads.
  def self.get_uploads(users, start_date: nil, end_date: nil, update_service: nil)
    upload_query = build_upload_query(users, start_date, end_date)
    new(upload_query, update_service).fetch_all_uploads
  end

  # Get data about how files are being used across Wikimedia sites.
  def self.get_usages(commons_uploads, update_service: nil)
    usage_query = build_usage_query commons_uploads
    new(usage_query, update_service).get_image_data('globalusage', 'gucontinue')
  end

  def self.find_missing_files(commons_uploads)
    missing_query = build_info_query(commons_uploads)
    pages = new(missing_query).get_image_data('pageid', '')
    missing_pages = pages.select { |page| page['missing'] }
    missing_page_ids = missing_pages.map { |page| page['pageid'] }
    commons_uploads.select { |file| missing_page_ids.include? file.id }
  end

  def self.get_urls(commons_uploads, update_service: nil)
    filename_query = build_info_query(commons_uploads)
    filename_response = new(filename_query).get_image_data('pageid', '')
    image_page_ids = []

    filename_response.each do |file_data|
      title = file_data['title']
      page_id = file_data['pageid']

      # mediawiki can generate thumbnails for jpg,png,tiff,wav files
      # mediawiki cannot generate thumbnails for pdf,djvu files
      if title.match?(/\.(pdf|djvu)$/i)
        bad_file = CommonsUpload.find_by(file_name: title)
        save_placeholder_thumbnail(bad_file) if bad_file
      else
        image_page_ids << page_id
      end
    end

    return {} if image_page_ids.empty?

    url_query = build_url_query(image_page_ids)
    new(url_query, update_service).get_image_data('imageinfo', 'iicontinue')
  end

  ##################
  # Query builders #
  ##################

  def self.build_upload_query(users, start_date, end_date)
    usernames = users.map(&:username)
    upload_query = { list: 'usercontribs',
                     ucuser: usernames,
                     ucnamespace: 6, # File: namespace
                     ucshow: 'new', # New pages ~= new uploads
                     uclimit: 500, # 500 is max for non-bots
                     continue: '' }
    # The Mediawiki API starts from the 'ucstart' and works backwards to 'ucend'
    # so we put the start_date for ucend and vice versa.
    upload_query[:ucend] = start_date.strftime('%Y%m%d%H%M%S') if start_date
    upload_query[:ucstart] = end_date.strftime('%Y%m%d%H%M%S') if end_date
    upload_query
  end

  def self.build_usage_query(commons_uploads)
    file_ids = commons_uploads.map(&:id)
    { prop: 'globalusage',
                    pageids: file_ids,
                    gulimit: 500, # 500 is max for non-bots
                    gufilterlocal: 'true', # Don't return local Commons usage
                    guprop: 'namespace', # Fetch NS for each usage
                    continue: '' }
  end

  def self.build_info_query(commons_uploads)
    file_ids = commons_uploads.map(&:id)
    { pageids: file_ids,
                   continue: '' }
  end

  def self.build_url_query(file_ids)
    { prop: 'imageinfo',
                  iiprop: 'url',
                  iiurlheight: 480,
                  pageids: file_ids,
                  iilimit: 50, # 50 is max when iiurlheight is used.
                  continue: '' }
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
      @image_data << r if r[@prop].present?
    end
    @continue = response['continue'] # nil if there is no continue
    return if @continue.nil?

    # Workaround for MediaWiki bug where continue runs the same query infinitely
    # https://phabricator.wikimedia.org/T101532
    @continue = nil if @query[@continue_param] == @continue[@continue_param]

    @query[@continue_param] = @continue[@continue_param] if @continue
  end

  ####################
  # Database methods #
  ####################
  def self.save_placeholder_thumbnail(file)
    file.thumburl = 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6c/No_image_3x4.svg/200px-No_image_3x4.svg.png'
    file.thumbwidth = 200
    file.thumbheight = 150
    file.save
  end

  ###################
  # Private methods #
  ###################
  private

  def api_get
    WikiApi.new(CommonsWiki.new, @update_service).query(@query)
  end
end
