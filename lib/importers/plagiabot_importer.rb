#= Imports plagiarism data from tools.wmflabs.org/eranbot/plagiabot/api.py
class PlagiabotImporter
  ################
  # Entry points #
  ################
  def self.check_recent_revisions
    revisions_to_check = Revision
                         .joins(:article)
                         .where { article.namespace == 0 }
                         .where('date > ?', 1.month.ago)
    revisions_to_check.each do |revision|
      pp "checking #{revision}"
      check_revision revision
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

  def self.query_url(revision_id)
    base_url = 'http://tools.wmflabs.org/eranbot/plagiabot/api.py'
    base_params = '?action=suspected_diffs&lang=en'
    diff_param = "&diff=#{revision_id}"
    url = base_url + base_params + diff_param
    url
  end

  ###############
  # API methods #
  ###############
  def self.api_get(revision_id)
    url = query_url(revision_id)
    response = Net::HTTP.get(URI.parse(url))
    response = response.gsub("'", '"')
    JSON.parse(response, quirks_mode: true)
  end
end
