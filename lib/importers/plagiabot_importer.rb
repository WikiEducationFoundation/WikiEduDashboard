#= Imports plagiarism data from tools.wmflabs.org/eranbot/plagiabot/api.py
class PlagiabotImporter
  ################
  # Entry points #
  ################

  # Checks each revision in our database against the plagiabot API
  def self.check_recent_revisions
    revisions_to_check = Revision
                         .joins(:article)
                         .where('articles.namespace = 0')
                         .where('date > ?', 1.month.ago)
    revisions_to_check.each do |revision|
      check_revision revision
    end
    import_report_urls
  end

  # Gets the most recent instances of plagiarism then matches them with
  # revisions in our database
  def self.find_recent_plagiarism
    suspected_diffs = api_get('suspected_diffs')
    suspected_diffs.select! { |rev| Revision.exists?(rev['diff']) }
    suspected_diffs.each do |rev|
      revision = Revision.find(rev['diff'])
      revision.ithenticate_id = rev['ithenticate_id']
      revision.save
    end
    import_report_urls
  end

  def self.import_report_urls
    # NOTE: This refetches all the urls on each update, because they expire
    # after a short time. It would be better to get the report url on an
    # as-needed basis by making the equivalent query from the client.
    revisions_to_update = Revision.where.not(ithenticate_id: nil)
    revisions_to_update.each do |revision|
      url = api_get_url(ithenticate_id: revision.ithenticate_id)
      revision.report_url = url
      revision.save
    end
  end

  ##################
  # Helper methods #
  ##################
  def self.check_revision(revision)
    response = api_get('suspected_diffs', revision_id: revision.id)
    return if response.empty?
    ithenticate_id = response[0]['ithenticate_id']
    revision.ithenticate_id = ithenticate_id
    revision.save
  end

  def self.query_url(type, opts = {})
    base_url = 'http://tools.wmflabs.org/eranbot/plagiabot/api.py'
    base_params = "?action=#{type}"
    url = base_url + base_params
    url += "&lang=en&diff=#{opts[:revision_id]}" if opts[:revision_id]
    url += "&report_id=#{opts[:ithenticate_id]}" if opts[:ithenticate_id]
    url
  end

  ###############
  # API methods #
  ###############
  def self.api_get(type, opts = {})
    url = query_url(type, opts)
    response = Net::HTTP.get(URI.parse(url))
    # Work around the not-quite-parseable format of the response.
    # We don't care about the title, we just want to make the response parseable.
    response = response.gsub(/: ".*"/, ": 'foo'") # replace any values with double parens
    response = response.gsub(/'page_title': '.*?', /, '') # remove the page_title keys/values
    response = response.tr("'", '"') # convert to double quotes per json standard

    JSON.parse(response)
  rescue Errno::ETIMEDOUT => e
    Raven.capture_exception e, level: 'warning'
    return nil
  end

  def self.api_get_url(opts = {})
    url = query_url('get_view_url', opts)
    response = Net::HTTP.get(URI.parse(url))
    response[1..-2]
  end
end
