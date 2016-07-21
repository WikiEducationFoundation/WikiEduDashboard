# Gets data from ORES — Objective Revision Evaluation Service
# https://meta.wikimedia.org/wiki/Objective_Revision_Evaluation_Service
class OresApi
  def initialize(wiki)
    raise InvalidProjectError unless wiki.project == 'wikipedia'
    @project_code = wiki.language + 'wiki'
  end

  def get_revision_data(rev_id)
    # TODO: i18n
    url = query_url(rev_id)
    response = Net::HTTP.get(URI.parse(url))
    ores_data = JSON.parse(response)
    ores_data
  rescue StandardError => error
    raise error unless typical_errors.include?(error.class)
    return {}
  end

  class InvalidProjectError < StandardError
  end

  private

  def query_url(rev_id)
    base_url = "https://ores.wikimedia.org/v2/scores/#{@project_code}/wp10/"
    url = base_url + rev_id.to_s + '/?features'
    url = URI.encode url
    url
  end

  def typical_errors
    [Errno::ETIMEDOUT,
     Net::ReadTimeout,
     Errno::ECONNREFUSED,
     JSON::ParserError,
     Errno::EHOSTUNREACH]
  end
end
