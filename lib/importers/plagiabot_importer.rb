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
    suspected_diffs = api_get
    suspected_diffs.select! { |rev| Revision.exists?(rev['diff']) }
    suspected_diffs.each do |rev|
      revision = Revision.find(rev['diff'])
      revision.ithenticate_id = rev['ithenticate_id']
      revision.save
    end
  end
  ##################
  # Helper methods #
  ##################
  def self.check_revision(revision)
    response = api_get(revision.id)
    return if response.empty?
    ithenticate_id = response[0]['ithenticate_id']
    revision.ithenticate_id = ithenticate_id
    revision.save
  end

  def self.query_url(opts = {})
    base_url = 'http://tools.wmflabs.org/eranbot/plagiabot/api.py'
    base_params = '?action=suspected_diffs&lang=en'
    diff_param = "&diff=#{opts[:revision_id]}"
    url = base_url + base_params + diff_param
    url
  end

  ###############
  # API methods #
  ###############
  def self.api_get(revision_id = nil)
    url = query_url(revision_id: revision_id)
    response = Net::HTTP.get(URI.parse(url))
    response = response.gsub("'", '"')
    JSON.parse(response, quirks_mode: true)
  end
end
