# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_utils"
require_dependency "#{Rails.root}/lib/replica"
require_dependency "#{Rails.root}/lib/importers/article_importer"
require_dependency "#{Rails.root}/app/helpers/encoding_helper"
require_dependency "#{Rails.root}/lib/importers/revision_score_importer"
require_dependency "#{Rails.root}/lib/duplicate_article_deleter"

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
  # This method gets course revisions for a given period.
  # Returns an array of Revision records.
  # As a side effect, it imports Article records.
  def fetch_revision_data_for_course(timeslice_start, timeslice_end)
    all_sub_data = get_course_revisions(@course.students, timeslice_start,
                                        timeslice_end)
    @revisions = []

    # Extract all article data from the slice. Outputs a hash with article attrs.
    articles = sub_data_to_article_attributes(all_sub_data)

    # Import articles. We do this here to avoid saving article data in memory.
    # Note that we create articles for all sub data (not only for scoped revisions).
    import_and_resolve_duplicate_articles articles

    # Prep: get a user dictionary for all users referred to by revisions.
    users = user_dict_from_sub_data(all_sub_data)

    # Now get all the revisions
    # We need a slightly different article dictionary format here
    article_dict = @articles.each_with_object({}) { |a, memo| memo[a.mw_page_id] = a.id }
    @revisions = sub_data_to_revision_attributes(all_sub_data,
                                                 users,
                                                 articles: article_dict)
    return @revisions
  end

  # This method gets scores for specific revisions from different APIs.
  # Returns an array of Revision records with completed scores.
  def fetch_score_data_for_course(revisions)
    @revisions = revisions

    # We need to partition revisions because we don't want to calculate scores for revisions
    # out of important spaces
    (revisions_in_spaces, revisions_out_spaces) = partition_revisions

    revisions_out_spaces.concat @importer.get_revision_scores(revisions_in_spaces)
  end

  # This method gets revisions for some specific users.
  # It does not fetch scores. It has no side effects.
  def fetch_revision_data_for_users(users, timeslice_start, timeslice_end)
    all_sub_data = get_course_revisions(users, timeslice_start, timeslice_end)
    users = user_dict_from_sub_data(all_sub_data)

    sub_data_to_revision_attributes(all_sub_data, users)
  end

  ###########
  # Helpers #
  ###########
  private

  def import_and_resolve_duplicate_articles(articles)
    ArticleImporter.new(@wiki, @course).import_articles_from_revision_data(articles)
    @articles = Article.where(wiki_id: @wiki.id, deleted: false,
                              mw_page_id: articles.map { |a| a['mw_page_id'] })
    DuplicateArticleDeleter.new(@wiki).resolve_duplicates_for_timeslices(@articles)
  end

  # Returns revisions for users during the given period.
  def get_course_revisions(users, start, end_date)
    all_sub_data = get_revisions(users, start, end_date)
    # Update the all_sub_data hash to mark scoped articles.
    # Important for ArticleScopedProgram/VisitingScholarship courses
    mark_scoped_articles(@wiki, all_sub_data)
  end

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

  # Returns revisions from all_sub_data.
  def sub_data_to_revision_attributes(all_sub_data, users, articles: nil)
    all_sub_data.flat_map do |_a_id, article_data|
      article_data['revisions'].map do |rev_data|
        create_revision(rev_data, article_data['article'], users, articles)
      end
    end.uniq(&:mw_rev_id)
  end

  # Updates the revision data with a new 'scoped' field inside the article data.
  # This field indicates if the article is scoped based on the course type.
  def mark_scoped_articles(wiki, revisions)
    revisions.each do |_, details|
      article_title = details['article']['title']
      formatted_article_title = ArticleUtils.format_article_title(article_title, wiki)
      mw_page_id = details['article']['mw_page_id'].to_i
      details['article']['scoped'] =
        @course.scoped_article?(wiki, formatted_article_title, mw_page_id)
    end
  end

  # Creates a revision record for the given revision data.
  def create_revision(rev_data, article_data, users, articles)
    mw_page_id = rev_data['mw_page_id'].to_i
    Revision.new({
          mw_rev_id: rev_data['mw_rev_id'],
          date: rev_data['date'],
          characters: rev_data['characters'] || 0,
          article_id: articles.nil? ? nil : articles[mw_page_id],
          mw_page_id:,
          user_id: users[rev_data['username']],
          new_article: string_to_boolean(rev_data['new_article']),
          system: string_to_boolean(rev_data['system']),
          wiki_id: rev_data['wiki_id'],
          scoped: article_data['scoped']
        })
  end

  # Partition revisions between those for which we want to calculate scores and
  # those for which we don't.
  # We want to calculate scores for scoped reivsions belonging to articles in
  # mainspace/userspace/draftspace.
  # We don't want to calculate scores for revisions in articles out of pertinent spaces or
  # for revisions which are not scoped (this is only important for articles with
  # only_scoped_articles_course? set to true).
  # Returns [scoped_revisions_in_spaces, non_scoped_revisions_or_out_spaces]
  def partition_revisions
    # Calculate articles out of mainspace/userspace/draftspace
    excluded_articles = @articles
                        .reject { |article| INCLUDED_NAMESPACES.include?(article.namespace) }
                        .map(&:mw_page_id).freeze

    # Note that scoped is always true for non-only-scoped-articles courses
    scoped_revisions_in_spaces = @revisions.select do |rev|
      (excluded_articles.exclude?(rev.mw_page_id) && rev.scoped)
    end
    [scoped_revisions_in_spaces, @revisions - scoped_revisions_in_spaces]
  end
end
