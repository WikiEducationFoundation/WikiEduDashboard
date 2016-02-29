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
    results = []
    return results if course.students.empty?
    start = course_start_date(course)
    end_date = course_end_date(course)
    new_users = users_with_no_revisions(course)

    old_users = course.students - new_users

    # TODO: Make a better educated guess about which wikis to search for edits.
    # Such as, course.assignments.map(&:wiki).uniq
    wikis = [Wiki.default_wiki]

    # rubocop:disable Style/IfUnlessModifier
    unless new_users.empty?
      results += get_revisions(new_users, start, end_date, wikis)
    end
    # rubocop:enable Style/IfUnlessModifier

    unless old_users.empty?
      first_rev = first_revision(course)
      start = first_rev.date.strftime('%Y%m%d') unless first_rev.blank?
      results += get_revisions(old_users, start, end_date)
    end
    results
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

  def self.users_with_no_revisions(course)
    course.users.role('student')
      .joins(:courses_users)
      .where({ courses_users: { revision_count: 0 }})
  end

  def self.first_revision(course)
    course.revisions.order('date DESC').first
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
    rev_ids = data.map do |_a_id, a|
      a['revisions'].map { |r| r['id'] }
    end
    rev_ids = rev_ids.flatten
    Revision.where(id: rev_ids)
  end

  def self.import_revisions_slice(sub_data)
    articles, revisions = [], []

    sub_data.each do |_a_id, a|
      article = Article.new(id: a['article']['id'])
      article.update(a['article'], false)
      articles.push article

      a['revisions'].each do |r|
        revision = Revision.new(id: r['id'])
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
    return if revisions.empty?

    synced_revisions = Utils.chunk_requests(revisions, 100) do |block|
      Replica.new(wiki).get_existing_revisions_by_id block
    end
    synced_ids = synced_revisions.map { |r| r['rev_id'].to_i }

    deleted_ids = revisions.pluck(:id) - synced_ids
    Revision.where(id: deleted_ids).update_all(deleted: true)
    Revision.where(id: synced_ids).update_all(deleted: false)

    moved_ids = synced_ids - deleted_ids
    moved_revisions = synced_revisions.reduce([]) do |moved, rev|
      moved.push rev if moved_ids.include? rev['rev_id'].to_i
    end
    moved_revisions.each do |moved|
      handle_moved_revision moved
    end
  end

  def self.handle_moved_revision(moved)
    article_id = moved['rev_page']
    Revision.find(moved['rev_id']).update(article_id: article_id)
    ArticleImporter
      .import_articles([article_id]) unless Article.exists?(article_id)
  end
end
