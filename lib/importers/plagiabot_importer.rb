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
      file_new_plagiarism_report(revision, rev['submission_id'])
    end
  end

  ##################
  # Helper methods #
  ##################
  def self.file_new_plagiarism_report(revision, submission_id)
    # This is just to log the fact that a revision got flagged
    revision.ithenticate_id = revision.mw_rev_id
    revision.save
    alert = PossiblePlagiarismAlert.new_from_revision(revision, submission_id)
    return unless alert
    SuspectedPlagiarismMailer.alert_content_expert(alert)
  end

  def self.query_url(type)
    base_url = 'https://ruby-suspected-plagiarism.toolforge.org/'
    url = base_url + type
    url
  end

  ###############
  # API methods #
  ###############
  def self.api_get(type)
    url = query_url(type)
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
