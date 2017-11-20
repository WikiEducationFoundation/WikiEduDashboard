# frozen_string_literal: true

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
  end

  # Gets the most recent instances of plagiarism then matches them with
  # revisions in our database
  def self.find_recent_plagiarism
    suspected_diffs = api_get('suspected_diffs')
    suspected_diffs.each do |rev|
      wiki = Wiki.find_by(language: rev['lang'], project: rev['project'])
      next unless wiki
      revision = Revision.find_by(mw_rev_id: rev['diff'], wiki_id: wiki.id)
      next unless revision
      file_new_plagiarism_report(revision, rev['ithenticate_id'])
    end
  end

  ##################
  # Helper methods #
  ##################
  def self.file_new_plagiarism_report(revision, ithenticate_id)
    return unless revision.ithenticate_id.nil?
    revision.ithenticate_id = ithenticate_id
    revision.save
    SuspectedPlagiarismMailer.alert_content_expert(revision)
  end

  def self.check_revision(revision)
    response = api_get('suspected_diffs', revision_id: revision.mw_rev_id)
    return if response.empty?
    ithenticate_id = response[0]['ithenticate_id']
    file_new_plagiarism_report(revision, ithenticate_id)
  end

  def self.query_url(type, opts = {})
    base_url = 'https://tools.wmflabs.org/eranbot/plagiabot/api.py'
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
  rescue StandardError => e
    raise e unless typical_errors.include?(e.class)
    Raven.capture_exception e, level: 'warning'
    return {}
  end

  def self.typical_errors
    [Errno::ETIMEDOUT,
     Net::ReadTimeout,
     JSON::ParserError]
  end

  def self.api_get_url(opts = {})
    url = query_url('get_view_url', opts)
    response = Net::HTTP.get(URI.parse(url))
    return response[1..-2] if response.include?('https://api.ithenticate.com/')
    return '/not_found'
  end
end
