require 'mediawiki_api'

class RevisionScoreImporter
  def self.update_revision_scores(articles)
    articles.each do |article|
      pp "importing #{article.title}"
      article.revisions.find_in_batches(batch_size: 50) do |rev_batch|
        rev_ids = rev_batch.map(&:id)
        scores = get_revision_scores rev_ids
        save_scores scores
      end
    end
  end

  def self.save_scores(scores)
    scores.each do |rev_id, score|
      revision = Revision.find(rev_id.to_i)
      revision.wp10 = weighted_mean_score score['probability']
      revision.save
    end
  end

  def self.get_parent_id(revision)
    rev_id = revision.id
    rev_query = revision_query(rev_id)
    response = wikipedia.query rev_query
    prev_id = response.data['pages'].values[0]['revisions'][0]['parentid']
    prev_id
  end

  def self.revision_query(rev_id)
    rev_query = { prop: 'revisions',
                  revids: rev_id,
                  rvprop: 'ids'
                }
    rev_query
  end

  def self.get_revision_scores(rev_ids)
    base_url = 'http://ores-staging.wmflabs.org/scores/enwiki/wp10/?revids='
    rev_ids_param = rev_ids.map(&:to_s).join('|')
    url = base_url + rev_ids_param
    url = URI.encode url
    response = Net::HTTP.get(URI.parse(url))
    scores = JSON.parse(response)
    scores
  end

  def self.weighted_mean_score(probability)
    mean = probability['FA'] * 100
    # mean += probability['A'] * 90
    mean += probability['GA'] * 80
    mean += probability['B'] * 50
    mean += probability['C'] * 40
    mean += probability['Start'] * 20
    mean += probability['Stub'] * 10
    mean
  end

  class << self
    private

    def wikipedia
      language = Figaro.env.wiki_language
      url = "https://#{language}.wikipedia.org/w/api.php"
      @wikipedia = MediawikiApi::Client.new url
      @wikipedia
    end
  end
end
