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
      user = User.find_by(username: rev['rev_user_text'])
      next unless user

      file_new_plagiarism_report(rev, wiki, user) unless alert_exists?(rev, user)
    end
  end

  ##################
  # Helper methods #
  ##################
  def self.file_new_plagiarism_report(rev_data, wiki, user)
    course = user.courses_users&.last&.course
    article = Article.find_by(title: rev_data['page_title'],
                              namespace: rev_data['page_namespace'],
                              wiki:)
    details = {
      submission_id: rev_data['submission_id'],
      mw_rev_id: rev_data['revision_id'],
      wiki_id: wiki.id
    }
    alert = PossiblePlagiarismAlert.create!(user:, course:, article:, details:)
    return unless alert
    SuspectedPlagiarismMailer.alert_content_expert(alert)
  end

  def self.query_url(type)
    base_url = 'https://ruby-suspected-plagiarism.toolforge.org/'
    url = base_url + type
    url
  end

  def self.alert_exists?(rev_data, user)
    PossiblePlagiarismAlert.where(user:).any? do |alert|
      alert.details[:submission_id] == rev_data['submission_id']
    end
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
