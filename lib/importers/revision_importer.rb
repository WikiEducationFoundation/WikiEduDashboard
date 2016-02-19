require "#{Rails.root}/lib/replica"
require "#{Rails.root}/lib/duplicate_article_deleter"
require "#{Rails.root}/lib/importers/article_importer"
require "#{Rails.root}/lib/importers/assignment_importer"

#= Imports and updates revisions from Wikipedia into the dashboard database
class RevisionImporter
  # FIXME: Too many static methods remaining.
  def initialize(wiki)
    @wiki = wiki
  end
  ################
  # Entry points #
  ################

  ##############
  # API Access #
  ##############
  def self.update_all_revisions(courses=nil, all_time=false)
    courses = [courses] if courses.is_a? Course
    courses ||= all_time ? Course.all : Course.current
    courses.each do |course|
      results = get_revisions_for_course(course)
      import_revisions(results)
      ArticlesCourses.update_from_course(course)
    end
  end

  # Given a Course, get new revisions for the users in that course.
  def self.get_revisions_for_course(course)
    return [] if course.students.empty?
    start_date = course_start_date(course)
    end_date = course_end_date(course)

    # TODO: Make a better educated guess about which wikis to search for edits.
    get_revisions(course.students, start_date, end_date, [course.home_wiki])
  end

  # Get revisions made by a set of users between two dates.
  def self.get_revisions(users, start, end_date, wikis)
    result_sets = wikis.map do |wiki|
      Utils.chunk_requests(users, 40) do |block|
        Replica.new(wiki).get_revisions block, start, end_date
      end
    end
    result_sets.reduce(:|)
  end

  ###########
  # Helpers #
  ###########
  def self.course_start_date(course)
    course.start.strftime('%Y%m%d')
  end

  # TODO: metrics_end_date, optionally never end
  def self.course_end_date(course)
    course.end.strftime('%Y%m%d')
  end

  # FIXME: Only used by tests
  def self.users_with_no_revisions(course)
    course.users.role('student')
      .joins(:courses_users)
      .where({ courses_users: { revision_count: 0 }})
  end

  def self.first_revision_date(course)
    # FIXME: Don't we want "date ASC"?
    first_revision = course.revisions.order('date DESC').first
    date = first_revision.date.strftime('%Y%m%d') unless first_revision.blank?
    date
  end

  def self.import_revisions(data)
    # Use revision data fetched from Replica to add new Revisions as well as
    # new Articles where appropriate.
    # Limit it to 8000 per slice to avoid running out of memory.
    data.each_slice(8000) do |sub_data|
      import_revisions_slice(sub_data)
    end

    # Some Assignments are for article titles that don't exist initially.
    # Some newly added Articles may correspond to those Assignments, in which
    # case the article_ids should be added.
    AssignmentImporter.update_assignment_article_ids
  end

  def self.get_revisions_from_import_data(data)
    revisions = []
    data.group_by { |a| a['article']['wiki_id'] }.each do |wiki_id, articles|
      rev_ids = []
      articles.each do |a|
        rev_ids |= a['revisions'].map { |r| r['rev_id'] }
      end
      revisions |= Revision.where(native_id: rev_ids, wiki_id: wiki_id)
    end
    revisions
  end

  def self.import_revisions_slice(sub_data)
    articles, revisions = [], []

    sub_data.each do |_a_id, a|
      article = Article.new(
        id: a['article']['page_id'], # TODO: Stop setting id
        native_id: a['article']['page_id'],
        wiki_id: a['article']['wiki_id']
      )
      article.update(a['article'], false)
      articles.push article

      a['revisions'].each do |r|
        revision = Revision.new(
          article_id: article.id,
          native_id: r['rev_id'],
          wiki_id: a['article']['wiki_id']
        )
        # FIXME: rev_id will be ignored, hopefully?  Need to set article_id?
        revision.update(r, false)
        revisions.push revision
      end
    end

    Article.import articles
    AssignmentImporter.update_article_ids(articles)
    DuplicateArticleDeleter.resolve_duplicates(articles)
    Revision.import revisions
  end

  def self.move_or_delete_revisions(revisions=nil)
    revisions ||= Revision.all

    revisions.group_by(&:wiki).each do |wiki, local_revisions|
      synced_revision_data = Utils.chunk_requests(local_revisions, 100) do |block|
        Replica.new(wiki).get_existing_revisions_by_id block
      end

      synced_revisions = synced_revision_data.map do |r|
        Revision.find_by(native_id: r['rev_id'], wiki_id: wiki.id).update(page_id: page_id)
      end

      deleted_revisions = local_revisions - synced_revisions
      # TODO: update_all
      deleted_revisions.each { |r| r.update(deleted: true) }
      synced_revisions.each { |r| r.update(deleted: false) }

      # FIXME: I broke this?
      moved_revisions = synced_revisions - deleted_revisions
      moved_revisions.each do |moved|
        handle_moved_revision moved
      end
    end
  end

  def self.handle_moved_revision(moved)
    page_id = moved.page_id
    Revision.find(native_id: moved.native_id, wiki_id: moved.wiki_id).update(page_id: page_id)

    article_exists = Article.where(native_id: page_id, wiki_id: moved.wiki_id).any?
    ArticleImporter.new(moved.wiki_id)
      .import_articles([page_id]) unless article_exists
  end
end
