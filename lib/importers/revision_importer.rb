require "#{Rails.root}/lib/replica"
require "#{Rails.root}/lib/importers/article_importer"
require "#{Rails.root}/lib/importers/assignment_importer"

#= Imports and updates revisions from Wikipedia into the dashboard database
class RevisionImporter
  ################
  # Entry points #
  ################

  ##############
  # API Access #
  ##############
  def self.update_all_revisions(courses=nil, all_time=false)
    results = []
    courses = [courses] if courses.is_a? Course
    courses ||= all_time ? Course.all : Course.current
    courses.each do |c|
      results += get_revisions_for_course(c)
    end

    import_revisions(results)

    result_revs = get_revisions_from_import_data(results)
    ArticlesCourses.update_from_revisions result_revs
  end

  # Given a Course, get new revisions for the users in that course.
  def self.get_revisions_for_course(c)
    results = []
    return results if c.students.empty?
    start = c.start.strftime('%Y%m%d')
    end_date = c.end.strftime('%Y%m%d')
    new_users = c.users.role('student').where(revision_count: 0)

    old_users = c.students - new_users

    # rubocop:disable Style/IfUnlessModifier
    unless new_users.empty?
      results += get_revisions(new_users, start, end_date)
    end
    # rubocop:enable Style/IfUnlessModifier

    unless old_users.empty?
      first_rev = c.revisions.order('date DESC').first
      start = first_rev.date.strftime('%Y%m%d') unless first_rev.blank?
      results += get_revisions(old_users, start, end_date)
    end
    results
  end

  # Get revisions made by a set of users between two dates.
  def self.get_revisions(users, start, end_date)
    Utils.chunk_requests(users, 40) do |block|
      Replica.get_revisions block, start, end_date
    end
  end

  ###########
  # Helpers #
  ###########
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
    ArticleImporter.resolve_duplicate_articles(articles)
    Revision.import revisions
  end

  def self.move_or_delete_revisions(revisions=nil)
    revisions ||= Revision.all
    return if revisions.empty?

    synced_revisions = Utils.chunk_requests(revisions, 100) do |block|
      Replica.get_existing_revisions_by_id block
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
    ArticleImporter.import_article(article_id) unless Article.exists?(article_id)
  end
end
