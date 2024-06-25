# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/replica"
require_dependency "#{Rails.root}/lib/importers/article_importer"
require_dependency "#{Rails.root}/app/helpers/encoding_helper"
require_dependency "#{Rails.root}/lib/importers/revision_score_importer"

#= Fetches revision data from API
class RevisionDataManager
  include EncodingHelper

  def initialize(wiki, course, update_service: nil)
    @wiki = wiki
    @course = course
    @update_service = update_service
    @importer = RevisionScoreImporter.new(wiki:, course:, update_service:)
  end

  INCLUDED_NAMESPACES = [0, 2, 118].freeze
  # This method gets revisions and scores for them from different APIs.
  # Returns an array of Revision records.
  # As a side effect, it imports Article records.
  def fetch_revision_data_for_course(timeslice_start, timeslice_end)
    sub_data = get_revisions(@course.students, timeslice_start, timeslice_end)
    @revisions = []

    # Extract all article data from the slice. Outputs a hash with article attrs.
    articles = sub_data_to_article_attributes(sub_data)

    # Import articles. We do this here to avoid saving article data in memory.
    ArticleImporter.new(@wiki).import_articles_from_revision_data(articles)
    @articles = Article.where(wiki_id: @wiki.id, mw_page_id: articles.map { |a| a['mw_page_id'] })

    # Prep: get a user dictionary for all users referred to by revisions.
    users = user_dict_from_sub_data(sub_data)

    # Now get all the revisions
    # We need a slightly different article dictionary format here
    article_dict = @articles.each_with_object({}) { |a, memo| memo[a.mw_page_id] = a.id }
    @revisions = sub_data_to_revision_attributes(sub_data, users, article_dict)

    # TODO: resolve duplicates
    # DuplicateArticleDeleter.new(@wiki).resolve_duplicates(@articles)

    # We need to partition revisions because we don't want to calculate scores for revisions
    # out of important spaces
    (revisions_in_spaces, revisions_out_spaces) = partition_revisions

    revisions_out_spaces.concat @importer.get_revision_scores(revisions_in_spaces)
  end

  ###########
  # Helpers #
  ###########
  private

  # Get revisions made by a set of users between two dates.
  # We limit the number of usernames per query in order to avoid
  # hitting the memory limit of the Replica endpoint.
  # TODO: For some reason, this returns duplicated mw_rev_id in the revisions data.
  # We should check if it's feasible to return unique mw_rev_id here.
  MAX_USERNAMES = 10
  def get_revisions(users, start, end_date)
    Utils.chunk_requests(users, MAX_USERNAMES) do |block|
      Replica.new(@wiki, @update_service).get_revisions block, start, end_date
    end
  end

  def string_to_boolean(string)
    case string
    when 'false'
      false
    when 'true'
      true
    end
  end

  def sub_data_to_article_attributes(sub_data)
    sub_data.map do |_a_id, article_data|
      {
        'mw_page_id' => article_data['article']['mw_page_id'],
        'wiki_id' => @wiki.id,
        'title' => sanitize_4_byte_string(article_data['article']['title']),
        'namespace' => article_data['article']['namespace']
      }
    end
  end

  def user_dict_from_sub_data(sub_data)
    users = sub_data.flat_map do |_a_id, article_data|
      article_data['revisions'].map { |rev_data| rev_data['username'] }
    end
    users.uniq!
    # Returns e.g. {"Nalumc"=>4, "Twkpassmore"=>3}
    User.where(username: users).pluck(:username, :id).to_h
  end

  def sub_data_to_revision_attributes(sub_data, users, articles)
    sub_data.flat_map do |_a_id, article_data|
      article_data['revisions'].map do |rev_data|
        mw_page_id = rev_data['mw_page_id'].to_i
        Revision.new({
          mw_rev_id: rev_data['mw_rev_id'],
          date: rev_data['date'],
          characters: rev_data['characters'],
          article_id: articles[mw_page_id],
          mw_page_id:,
          user_id: users[rev_data['username']],
          new_article: string_to_boolean(rev_data['new_article']),
          system: string_to_boolean(rev_data['system']),
          wiki_id: rev_data['wiki_id']
        })
      end
    end.uniq(&:mw_rev_id)
  end

  # Partition revisions between those belonging to articles in/out of mainspace/userspace/draftspace
  # We need this to avoid calculating scores for articles out of pertinent spaces
  # Returns [revisions_in_spaces, revisions_out_spaces]
  def partition_revisions
    # Calculate articles out of mainspace/userspace/draftspace
    excluded_articles = @articles
                        .reject { |article| INCLUDED_NAMESPACES.include?(article.namespace) }
                        .map(&:mw_page_id).freeze

    [@revisions.select { |rev| excluded_articles.exclude?(rev.mw_page_id) },
     @revisions.select { |rev| excluded_articles.include?(rev.mw_page_id) }]
  end
end
