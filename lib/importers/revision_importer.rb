# frozen_string_literal: true
require "#{Rails.root}/lib/replica"
require "#{Rails.root}/lib/duplicate_article_deleter"
require "#{Rails.root}/lib/importers/article_importer"
require "#{Rails.root}/lib/importers/assignment_importer"

#= Imports and updates revisions from Wikipedia into the dashboard database
class RevisionImporter
  def initialize(wiki = nil)
    wiki ||= Wiki.default_wiki
    @wiki = wiki
  end

  ################
  # Entry points #
  ################

  def self.update_all_revisions(courses=nil, all_time=false)
    courses = [courses] if courses.is_a? Course
    courses ||= all_time ? Course.all : Course.current
    courses.each do |course|
      wiki_ids = course.assignments.pluck(:wiki_id) + [course.home_wiki.id]
      wiki_ids.uniq.each do |wiki_id|
        importer = new(Wiki.find(wiki_id))
        results = importer.get_revisions_for_course(course)
        importer.import_revisions(results)
      end
      ArticlesCourses.update_from_course(course)
    end
  end

  # Given a Course, get new revisions for the users in that course.
  def get_revisions_for_course(course)
    results = []
    return results if course.students.empty?
    start = course_start_date(course)
    end_date = end_of_update_period(course)
    new_users = users_with_no_revisions(course)

    old_users = course.students - new_users

    # rubocop:disable Style/IfUnlessModifier
    unless new_users.empty?
      results += get_revisions(new_users, start, end_date)
    end
    # rubocop:enable Style/IfUnlessModifier

    unless old_users.empty?
      first_rev = first_revision(course)
      start = first_rev.date.strftime('%Y%m%d') unless first_rev.blank?
      results += get_revisions(old_users, start, end_date)
    end
    results
  end

  def move_or_delete_revisions(revisions=nil)
    # NOTE: All revisions passed to this method should be from the same @wiki.
    revisions ||= Revision.where(wiki_id: @wiki.id)
    return if revisions.empty?

    synced_revisions = Utils.chunk_requests(revisions, 100) do |block|
      Replica.new(@wiki).get_existing_revisions_by_id block
    end
    synced_rev_ids = synced_revisions.map { |r| r['rev_id'].to_i }

    deleted_rev_ids = revisions.pluck(:mw_rev_id) - synced_rev_ids
    Revision.where(wiki_id: @wiki.id, mw_rev_id: deleted_rev_ids)
            .update_all(deleted: true)
    Revision.where(wiki_id: @wiki.id, mw_rev_id: synced_rev_ids)
            .update_all(deleted: false)

    moved_ids = synced_rev_ids - deleted_rev_ids
    moved_revisions = synced_revisions.reduce([]) do |moved, rev|
      moved.push rev if moved_ids.include? rev['rev_id'].to_i
    end
    moved_revisions.each do |moved|
      handle_moved_revision moved
    end
  end

  def import_revisions(data)
    # Use revision data fetched from Replica to add new Revisions as well as
    # new Articles where appropriate.
    # Limit it to 8000 per slice to avoid running out of memory.
    data.each_slice(8000) do |sub_data|
      import_revisions_slice(sub_data)
    end
  end

  ###########
  # Helpers #
  ###########
  private

  # Get revisions made by a set of users between two dates.
  def get_revisions(users, start, end_date)
    Utils.chunk_requests(users, 40) do |block|
      Replica.new(@wiki).get_revisions block, start, end_date
    end
  end

  def course_start_date(course)
    course.start.strftime('%Y%m%d')
  end

  DAYS_TO_IMPORT_AFTER_COURSE_END = 30
  def end_of_update_period(course)
    # Add one day so that the query does not end at the beginning of the last day.
    (course.end + 1.day + DAYS_TO_IMPORT_AFTER_COURSE_END.days).strftime('%Y%m%d')
  end

  def users_with_no_revisions(course)
    course.users.role('student')
          .joins(:courses_users)
          .where(courses_users: { revision_count: 0 })
  end

  def first_revision(course)
    course.revisions.where(wiki_id: @wiki.id).order('date DESC').first
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

  def handle_moved_revision(moved)
    mw_page_id = moved['rev_page']

    unless Article.exists?(wiki_id: @wiki.id, mw_page_id: mw_page_id)
      ArticleImporter.new(@wiki).import_articles([mw_page_id])
    end

    article = Article.find_by(wiki_id: @wiki.id, mw_page_id: mw_page_id)

    # Don't update the revision to point to a new article if there isn't one.
    # This may happen if the article gets moved and then deleted, and there's
    # some inconsistency or timing delay in the update process.
    return unless article

    Revision.find_by(wiki_id: @wiki.id, mw_rev_id: moved['rev_id'])
            .update(article_id: article.id, mw_page_id: mw_page_id)
  end

  def string_to_boolean(string)
    return false if string == 'false'
    return true if string == 'true'
  end
end
