require "#{Rails.root}/lib/importers/revision_importer"

#= Cleaners
class Cleaners
  ####################
  # Articles Courses #
  ####################
  def self.remove_bad_articles_courses
    non_student_cus = CoursesUsers.where(role: [1, 2, 3, 4])
    non_student_cus.each do |nscu|
      remove_bad_articles_courses_for_course_user nscu
    end
  end

  def self.rebuild_articles_courses(courses=nil)
    courses ||= Course.current
    user_ids = []
    courses.each do |course|
      user_ids += course.students.pluck(:id)
    end
    user_ids.uniq!
    revisions = Revision.where(user_id: user_ids)
    ArticlesCourses.update_from_revisions revisions
  end

  ############
  # Articles #
  ############
  def self.remove_bad_articles_courses_for_course_user(course_user)
    course = course_user.course
    user_id = course_user.user_id
    # Check if the non-student user is also a student in the same course.
    return if course_user.user.student?(course)

    user_articles = find_user_articles(course_user, course)
    return if user_articles.empty?

    course_articles = course.articles.pluck(:id)
    possible_deletions = course_articles & user_articles

    to_delete = []
    possible_deletions.each do |a_id|
      to_delete.push a_id unless other_editors_in_course?(a_id, user_id, course)
    end

    # remove orphaned articles from the course
    course.articles.delete(Article.find(to_delete))
    Rails.logger.info(
      "Deleted #{to_delete.size} ArticlesCourses from #{course.title}"
    )
    # update course cache to account for removed articles
    course.update_cache unless to_delete.empty?
  end

  def self.other_editors_in_course?(article_id, user_id, course)
    other_editors = Article.find(article_id).editors - [user_id]
    return false if other_editors.empty?
    course_editors = course.students & other_editors
    return false if course_editors.empty?
    true
  end

  def self.find_user_articles(course_user, course)
    course_user
      .user.revisions
      .where('date >= ?', course.start)
      .where('date <= ?', course.end)
      .pluck(:article_id)
  end

  #############
  # Revisions #
  #############
  def self.repair_orphan_revisions
    orphan_revisions = find_orphan_revisions
    return if orphan_revisions.blank?

    start = before_earliest_revision(orphan_revisions)
    end_date = after_latest_revision(orphan_revisions)

    user_ids = orphan_revisions.pluck(:user_id).uniq
    users = User.where(id: user_ids)

    revision_data = RevisionImporter.get_revisions(users, start, end_date)
    RevisionImporter.import_revisions(revision_data)

    revs = RevisionImporter.get_revisions_from_import_data(revision_data)
    Rails.logger.info "Imported articles for #{revs.count} revisions"

    ArticlesCourses.update_from_revisions revs unless revs.blank?
  end

  def self.find_orphan_revisions
    article_ids = Article.all.pluck(:id)
    orphan_revisions = Revision.where
                       .not(article_id: article_ids)
                       .order('date ASC')

    Rails.logger.info "Found #{orphan_revisions.count} orphan revisions"
    orphan_revisions
  end

  def self.before_earliest_revision(revisions)
    date = revisions.first.date - 1.day
    date.strftime('%Y%m%d')
  end

  def self.after_latest_revision(revisions)
    date = revisions.last.date + 1.day
    date.strftime('%Y%m%d')
  end

  ###############
  # Assignments #
  ###############
  def self.repair_case_variant_assignment_titles
    assignments = Assignment.all
    assignments.each do |assignment|
      article_title = assignment.article_title
      article_id = assignment.article_id
      if article_id && Article.exists?(article_id)
        assignment.article_title = Article.find(article_id).title
        assignment.save
      elsif title_not_capitalized?(article_title)
        assignment.article_title = capitalize_article_title(article_title)
        assignment.save
      end
    end
  end

  def self.title_not_capitalized?(article_title)
    article_title != capitalize_article_title(article_title)
  end

  def self.capitalize_article_title(article_title)
    # Use mb_chars so that we can capitalize unicode letters too.
    article_title.mb_chars.capitalize.to_s
  end
end
