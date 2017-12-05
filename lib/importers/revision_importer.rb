# frozen_string_literal: true

require "#{Rails.root}/lib/replica"
require "#{Rails.root}/lib/duplicate_article_deleter"
require "#{Rails.root}/lib/importers/article_importer"

#= Imports and updates revisions from Wikipedia into the dashboard database
class RevisionImporter
  def initialize(wiki, course)
    @wiki = wiki
    @course = course
  end

  def import_new_revisions_for_course
    import_revisions(new_revisions_for_course)
  end

  ###########
  # Helpers #
  ###########
  private

  # Given a Course, get new revisions for the users in that course.
  def new_revisions_for_course
    results = []

    # Users with no revisions are considered "new". For them, we search for
    # revisions starting from the beginning of the course, in case they were
    # just added to the course.
    @new_users = users_with_no_revisions
    results += revisions_from_new_users unless @new_users.empty?

    # For users who already have revisions during the course, we assume that
    # previous updates imported their revisions prior to the latest revisions.
    # We only need to import revisions
    @old_users = @course.students - @new_users
    results += revisions_from_old_users unless @old_users.empty?
    results
  end

  def revisions_from_new_users
    get_revisions(@new_users, course_start_date, end_of_update_period)
  end

  def revisions_from_old_users
    first_rev = latest_revision_of_course
    start = first_rev.blank? ? course_start_date : first_rev.date.strftime('%Y%m%d')
    get_revisions(@old_users, start, end_of_update_period)
  end

  def import_revisions(data)
    # Use revision data fetched from Replica to add new Revisions as well as
    # new Articles where appropriate.
    # Limit it to 8000 per slice to avoid running out of memory.
    data.each_slice(8000) do |sub_data|
      import_revisions_slice(sub_data)
    end
  end

  # Get revisions made by a set of users between two dates.
  def get_revisions(users, start, end_date)
    Utils.chunk_requests(users, 40) do |block|
      Replica.new(@wiki).get_revisions block, start, end_date
    end
  end

  def course_start_date
    @course.start.strftime('%Y%m%d')
  end

  # pull all revisions until present, so that we have any after-the-end revisions
  # included for calculating retention when a past course gets updated.
  def end_of_update_period
    2.days.from_now.strftime('%Y%m%d')
  end

  def users_with_no_revisions
    @course.users.role('student')
           .joins(:courses_users)
           .where(courses_users: { revision_count: 0 })
  end

  def latest_revision_of_course
    @course.revisions.where(wiki_id: @wiki.id).order('date DESC').first
  end

  def import_revisions_slice(sub_data)
    @articles, @revisions = [], []

    sub_data.each do |_a_id, article_data|
      process_article_and_revisions(article_data)
    end

    DuplicateArticleDeleter.new(@wiki).resolve_duplicates(@articles)
    Revision.import @revisions
  end

  def process_article_and_revisions(article_data)
    article = article_updated_from_data(article_data)
    @articles.push article

    article_data['revisions'].each do |rev_data|
      push_revision_record(rev_data, article)
    end
  end

  def article_updated_from_data(article_data)
    article = Article.find_by(mw_page_id: article_data['article']['mw_page_id'], wiki_id: @wiki.id)
    article ||= Article.new(mw_page_id: article_data['article']['mw_page_id'], wiki_id: @wiki.id)
    article.update!(title: article_data['article']['title'],
                    namespace: article_data['article']['namespace'])
    article
  end

  def push_revision_record(rev_data, article)
    existing_revision = Revision.find_by(mw_rev_id: rev_data['mw_rev_id'], wiki_id: @wiki.id)
    return unless existing_revision.nil?
    revision = revision_from_data(rev_data, article)
    @revisions.push revision
  end

  def revision_from_data(rev_data, article)
    Revision.new(mw_rev_id: rev_data['mw_rev_id'],
                 date: rev_data['date'],
                 characters: rev_data['characters'],
                 article_id: article.id,
                 mw_page_id: rev_data['mw_page_id'],
                 user_id: User.find_by(username: rev_data['username'])&.id,
                 new_article: string_to_boolean(rev_data['new_article']),
                 system: string_to_boolean(rev_data['system']),
                 wiki_id: rev_data['wiki_id'])
  end

  def string_to_boolean(string)
    return false if string == 'false'
    return true if string == 'true'
  end
end
