# frozen_string_literal: true

#= Imports plagiarism data from https://ruby-suspected-plagiarism.toolforge.org/
#= See https://github.com/WikiEducationFoundation/ruby-suspected-plagiarism
class PlagiabotImporter
  ################
  # Entry points #
  ################

  # Gets the most recent instances of plagiarism then matches them with
  # revisions in our database
  def self.find_recent_plagiarism
    suspected_diffs = api_get('suspected_diffs')
    suspected_diffs.each do |rev|
      wiki = Wiki.find_by(language: rev['lang'], project: rev['project'])
      next unless wiki
      revision = Revision.find_by(mw_rev_id: rev['rev_id'], wiki_id: wiki.id)
      next unless revision
      file_new_plagiarism_report(revision, rev['ithenticate_id'])
    end
  end

  # Fetches an ithenticate report URL
  def self.api_get_url(opts = {})
    url = query_url('ithenticate_report_url', opts)
    response = Net::HTTP.get(URI.parse(url))
    return response if response.include?('https://api.ithenticate.com/')
    return '/not_found'
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

  def self.query_url(type, opts = {})
    base_url = 'https://ruby-suspected-plagiarism.toolforge.org/'
    url = base_url + type
    url += "/#{opts[:ithenticate_id]}" if opts[:ithenticate_id]
    url
  end

  ###############
  # API methods #
  ###############
  def self.api_get(type, opts = {})
    url = query_url(type, opts)
    response = Net::HTTP.get(URI.parse(url))
    Oj.load(response)
  rescue StandardError => e
    raise e unless typical_errors.include?(e.class)
    Sentry.capture_exception e, level: 'warning', extra: { response: @response }
    return {}
  end

  def self.typical_errors
    [Oj::ParseError,
     Errno::ETIMEDOUT]
  end
end
