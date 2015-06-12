require 'mediawiki_api'

class RevisionScoreImporter
  def self.update_revision_scores(articles)
    articles.each do |article|
      pp "importing #{article.title}"
      first = article.revisions.first
      last = article.revisions.last
      last.wp10 = get_revision_score last.id
      last.save
      first_parent_id = get_parent_id first
      first.wp10_previous = get_revision_score first_parent_id
      first.save
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

  def self.get_revision_score(rev_id)
    base_url = 'http://ores-test.wmflabs.org/scores/enwiki/wp10/'
    url = base_url + rev_id.to_s + '/'
    response = Net::HTTP.get(URI.parse(url))
    score = JSON.parse(response)
    prediction = score[rev_id.to_s]['prediction']
    prediction
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
