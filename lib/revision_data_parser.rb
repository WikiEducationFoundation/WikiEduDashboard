class RevisionDataParser
  def initialize(wiki)
    @wiki = wiki
  end

  # Given a single raw json revision, parse it into a more useful format.
  #
  # Example raw revision input:
  #   {
  #     "page_id"=>"418355", "page_title"=>"Babbling", "page_namespace"=>"0",
  #     "rev_id"=>"641327984", "rev_timestamp"=>"20150107003430",
  #     "rev_user_text"=>"Ragesoss", "rev_user"=>"319203",
  #     "new_article"=>"false", "byte_change"=>"121"
  #   }
  #
  # Example parsed revision output:
  #  {
  #     "revision"=>{
  #       "id"=>"641327984", "date"=>Wed, 07 Jan 2015 00:34:30 +0000,
  #       "characters"=>"121", "article_id"=>"418355", "user_id"=>"319203",
  #       "new_article"=>"false"}, "article"=>{"id"=>"418355",
  #       "title"=>"Babbling", "namespace"=>"0"
  #     }
  #   }
  def parse_revision(revision)
    article_data = parse_article_data(revision)
    revision_data = parse_revision_data(revision)

    { 'article' => article_data, 'revision' => revision_data }
  end

  private

  def parse_article_data(revision)
    article_data = {}
    # TODO: decouple id from mw_page_id
    article_data['id'] = revision['page_id']
    article_data['mw_page_id'] = revision['page_id']
    article_data['title'] = revision['page_title']
    article_data['namespace'] = revision['page_namespace']
    article_data['wiki_id'] = @wiki.id
    article_data
  end

  def parse_revision_data(revision)
    revision_data = {}
    # TODO: decouple id from mw_rev_id
    revision_data['id'] = revision['rev_id']
    revision_data['mw_rev_id'] = revision['rev_id']
    revision_data['date'] = revision['rev_timestamp'].to_datetime
    revision_data['characters'] = revision['byte_change']
    # TODO: decouple article_id from mw_page_id
    revision_data['article_id'] = revision['page_id']
    revision_data['mw_page_id'] = revision['page_id']
    revision_data['user_id'] = revision['rev_user']
    revision_data['new_article'] = revision['new_article']
    revision_data['system'] = revision['system']
    revision_data['wiki_id'] = @wiki.id
    revision_data
  end
end
