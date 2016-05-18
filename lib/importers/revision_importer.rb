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
    end_date = course_end_date(course)
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

  def get_revisions_for_users(users, start, end_date)
    revision_data = get_revisions(users, start, end_date)
    import_revisions(revision_data)
    revisions = get_revisions_from_import_data(revision_data)
    revisions
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

    # Some Assignments are for article titles that don't exist initially.
    # Some newly added Articles may correspond to those Assignments, in which
    # case the article_ids should be added.
    AssignmentImporter.update_assignment_article_ids
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

  def course_end_date(course)
    # Add one day so that the query does not end at the beginning of the last day.
    (course.end + 1.day).strftime('%Y%m%d')
  end

  def users_with_no_revisions(course)
    course.users.role('student')
          .joins(:courses_users)
          .where(courses_users: { revision_count: 0 })
  end

  def first_revision(course)
    course.revisions.where(wiki_id: @wiki.id).order('date DESC').first
  end

  def get_revisions_from_import_data(data)
    rev_ids = data.map do |_a_id, a|
      a['revisions'].map { |r| r['id'] }
    end
    rev_ids = rev_ids.flatten
    Revision.where(wiki_id: @wiki.id, mw_rev_id: rev_ids)
  end

  def import_revisions_slice(sub_data)
    articles, revisions = [], []

    sub_data.each do |_a_id, a|
      article = Article.find_by(mw_page_id: a['article']['mw_page_id'], wiki_id: @wiki.id)
      article ||= Article.new(mw_page_id: a['article']['mw_page_id'], wiki_id: @wiki.id)
      article.update!(title: a['article']['title'],
                      namespace: a['article']['namespace'])
      articles.push article

      a['revisions'].each do |r|
        existing_revision = Revision.find_by(mw_rev_id: r['mw_rev_id'], wiki_id: @wiki.id)
        next unless existing_revision.nil?
        revision = Revision.new(mw_rev_id: r['mw_rev_id'],
                                date: r['date'],
                                characters: r['characters'],
                                article_id: article.id,
                                mw_page_id: r['mw_page_id'],
                                user_id: User.find_by(username: r['username']).try(:id),
                                new_article: r['new_article'],
                                system: r['system'],
                                wiki_id: r['wiki_id'])
        revisions.push revision
      end
    end

    AssignmentImporter.update_article_ids(articles, @wiki)
    DuplicateArticleDeleter.new(@wiki).resolve_duplicates(articles)
    Revision.import revisions
  end

  def handle_moved_revision(moved)
    mw_page_id = moved['rev_page']

    unless Article.exists?(wiki_id: @wiki.id, mw_page_id: mw_page_id)
      ArticleImporter.new(@wiki).import_articles([mw_page_id])
    end

    article = Article.find_by(wiki_id: @wiki.id, mw_page_id: mw_page_id)
    article_id = article.try(:id)

    Revision.find_by(wiki_id: @wiki.id, mw_rev_id: moved['rev_id'])
            .update(article_id: article_id, mw_page_id: mw_page_id)
  end
end
